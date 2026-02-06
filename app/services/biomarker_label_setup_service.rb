class BiomarkerLabelSetupService
  def initialize(file_path = nil)
    @file_path = file_path || Rails.root.join('external-files', 'seed-files', 'seeds-biomarker-labels.xlsx')
    @parser = ExcelParserService.new(@file_path)
    @stats = {
      labels_created: 0,
      label_relationships_created: 0,
      label_assignments_created: 0,
      errors: []
    }
  end

  def call
    puts "Starting Biomarker Label Setup Service"
    puts "Reading Excel file from: #{@file_path}"

    ActiveRecord::Base.transaction do
      create_labels
      create_label_relationships
      create_label_assignments
    end

    @stats
  rescue => e
    @stats[:errors] << "Service failed: #{e.message}"
  end

  private

  def create_labels
    puts "Creating labels..."
    labels_data = @parser.parse_sheet('labels')
    labels_data.each do |label_data|
      begin
        label = Label.find_or_create_by(name: label_data[:name])
        @stats[:labels_created] += 1 if label.persisted? && label.previously_new_record?
      rescue => e

        @stats[:errors] << "Error creating label '#{label_data[:name]}': #{e.message}"

        @stats[:labels_created] = 0
        @stats[:label_relationships_created] = 0
        @stats[:label_assignments_created] = 0
      end
    end
  end

  def create_label_relationships
    puts "Creating label relationships..."
    relationships_data = @parser.parse_sheet('label_relationships')
    relationships_data.each do |relationship_data|
      begin
        parent_label = Label.find_by(name: relationship_data[:parent_label_name])
        child_label = Label.find_by(name: relationship_data[:child_label_name])

        if parent_label && child_label
          relationship = LabelRelationship.find_or_create_by(
            parent_label: parent_label,
            child_label: child_label
          )
          @stats[:label_relationships_created] += 1 if relationship.persisted? && relationship.previously_new_record?
        else
          @stats[:errors] << "Invalid label relationship: #{relationship_data.inspect}"
        end
      rescue => e
        @stats[:errors] << "Error creating label relationship: '#{relationship_data.inspect}': #{e.message}"

        # Reset stats if rollback is raised -> any error in the transaction will roll back the transaction
        @stats[:labels_created] = 0
        @stats[:label_relationships_created] = 0
        @stats[:label_assignments_created] = 0
      end
    end
  end


  def create_label_assignments
    puts "Creating label assignments..."
    assignments_data = @parser.parse_sheet('label_assignments')

    assignments_data.each do |assignment_data|
      begin
        label = Label.find_by(name: assignment_data[:label_name])
        biomarker = Biomarker.find_by(external_ref: assignment_data[:biomarker_external_ref].to_i)

        if label && biomarker
          assignment = LabelAssignment.find_or_create_by(
            label: label,
            labelable: biomarker
          )
          @stats[:label_assignments_created] += 1 if assignment.persisted? && assignment.previously_new_record?
        else
          @stats[:errors] << "Invalid label assignment: '#{assignment_data.inspect}'"
        end
      rescue => e
        @stats[:errors] << "Error creating label assignment: '#{assignment_data.inspect}': #{e.message}"

        # Reset stats if rollback is raised -> any error in the transaction will roll back the transaction
        @stats[:labels_created] = 0
        @stats[:label_relationships_created] = 0
        @stats[:label_assignments_created] = 0
      end
    end
  end
end

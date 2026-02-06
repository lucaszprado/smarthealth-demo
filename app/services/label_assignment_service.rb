class LabelAssignmentService
  def self.create(labelable, label_params)
    label_categories_id = [:label_system_id, :label_organ_id, :label_part_id, :label_spacial_group_id, :label_positioning_id]
    created_labels = []
    
    ActiveRecord::Base.transaction do
      label_categories_id.each do |category|
        if label_params[category] != [""]

          label_ids = Array(label_params[category]) # Ensure label_ids is always an array, eitheir label_params[category] is a single value or an array.

          label_ids.each do |label_id|
            if label_id != ""
              label = Label.find_by(id: label_id)
              unless label
                raise ActiveRecord::Rollback, "Label with ID #{label_id} not found"
              end

              LabelAssignment.create!(
                label: label,
                labelable: labelable
              )
              created_labels << label
            end
          end
        end
      end
    end

    return created_labels

  rescue => e
    Rails.logger.error "LabelAssignmentService Error: #{e.message}"
    return nil
  end
end

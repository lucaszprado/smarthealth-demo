# Service to transform flat biomarker list into sectioned list based on label classification
class BiomarkerSectionsService
  # Default label order - can be overridden for different contexts.

  DEFAULT_LABEL_ORDER = [
    "Hemograma",
    "Lipídeos",
    "Glicose e Metabolismo dos carboidratos",
    "Estudos hormonais"
  ].freeze # makes the array immutable, preventing any modifications to it.


  def initialize(label_order = nil)
    @label_order = label_order || DEFAULT_LABEL_ORDER
    @parent_label = Label.find_by(name: "Biomarcador")
  end


  # Transforms a flat list of biomarkers into a sectioned array grouped by label.
  #
  # @param biomarkers [Array<Hash>] Flat list of biomarkers from FilterQueryService
  # @return [Array<Hash>] Array of section objects, each with a label, ordered/grouped biomarkers
  # @example Return value
  #   [
  #     {
  #       label: "Hemograma",
  #       biomarkers: [
  #         { biomarker_id: 1, display_name: "Hemoglobina", ... },
  #         { biomarker_id: 2, display_name: "Hematócrito", ... }
  #       ]
  #     },
  #     {
  #       label: "Lipídeos",
  #       biomarkers: [
  #         { biomarker_id: 3, display_name: "Colesterol Total", ... }
  #       ]
  #     },
  #     {
  #       label: "Outros Biomarcadores",
  #       biomarkers: [
  #         { biomarker_id: 50, display_name: "Vitamina D", ... }
  #       ]
  #     }
  #   ]
  def call(biomarkers)
    return [] if biomarkers.blank?

    # 1. Group biomarkers by their primary Label
    grouped_biomarkers = group_biomarkers_by_label(biomarkers)

    # 2. Create section objects in the specified order
    create_sections(grouped_biomarkers)
  end

  private


  # Group biomarkers by their primary label (first label with parent "Biomarcador")
  # @param biomarkers [Array<Hash>] Flat list of biomarkers
  # @return [Hash<String, Array<Hash>>] Biomarkers grouped by label name
  def group_biomarkers_by_label(biomarkers)
    grouped = {}
    others = []

    biomarkers.each do |biomarker|
      primary_label = find_primary_label(biomarker[:biomarker_id])

      if primary_label
        grouped[primary_label.name] ||= [] #  initialize an empty array for a label name if it doesn't already exist in the grouped hash. /n Lazy hash initialization.
        grouped[primary_label.name] << biomarker
      else
        others << biomarker
      end
    end

    # Add unlabeled biomarkers to "Others" section
    grouped["Outros Biomarcadores"] = others if others.any?

    grouped
  end

  # Find the primary label for a biomarker (first label with parent "Biomarcador")
  # @param biomarker_id [Integer] The biomarker ID
  # @return [Label, nil] The primary label or nil if not found
  def find_primary_label(biomarker_id)
    return nil unless biomarker_id && @parent_label

    biomarker = Biomarker.find(biomarker_id)
    return nil unless biomarker

    # Find first label with parent label = Biomarcador for biomarker
    biomarker.labels.joins(:parent_relationships).where(parent_relationships: {parent_label: @parent_label}).order(created_at: :asc).first
  end

  # Create section objects in the specified order
  # @param grouped_biomarkers [Hash<String, Array<Hash>>] Biomarkers grouped by label
  # @return [Array<Hash>] Array of section objects
  def create_sections(grouped_biomarkers)
    sections = []
    @label_order.each do |label_name|
      biomarkers = grouped_biomarkers[label_name]
      next if biomarkers.blank?

      sections << {
        name: label_name,
        order: @label_order.index(label_name),
        count: biomarkers.count,
        biomarkers: biomarkers
      }
    end

    # Add any remaining sections not in the predefined order
    # Iterates over the grouped_biomarkers hash -> @return of group_biomarkers_by_label
    grouped_biomarkers.each do |label_name, biomarkers|
      next if @label_order.include?(label_name)
      next if biomarkers.blank?

      sections << {
        name: label_name,
        order: @label_order.length + sections.length + 1,
        count: biomarkers.count,
        biomarkers: biomarkers
      }
    end

    sections
  end
end

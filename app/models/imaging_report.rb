class ImagingReport < ApplicationRecord
  belongs_to :source
  belongs_to :imaging_method
  belongs_to :report_summary, optional: true
  has_many :label_assignments, as: :labelable, dependent: :destroy
  has_many :labels, through: :label_assignments
  has_one :health_professional, through: :source
  has_one :health_provider, through: :source

  # Deleting an imaging_report will also delete its source
  # Source was defined as has_many imaging_reports
  # Because of that we can't use dependent: :destroy on ImagingReport Model
  # Until we refactor the code, we'll do this by a callback method
  after_destroy :destroy_source


  def self.ransackable_attributes(auth_object = nil)
    ["content", "created_at", "date", "id", "id_value", "imaging_method_id", "report_summary_id", "source_id", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["imaging_method", "label_assignments", "labels", "report_summary", "source"]
  end


  def self.find_structured(id)
    find(id).to_structured_data
  end

  # Search imaging reports for a given human and return structured data
  def self.search_for_human(human_id, query = nil)
    # 1. Build ActiveRecord collection of imaging_reports -> Simillar an array
    base_query = joins(source: :human) # As we're definig a class method in ImagingRport -> This join will be called on ImagingReport when this method is called.
      .joins(:imaging_method)
      .where(sources: {human_id: human_id})
      .includes(:labels, source: [:health_professional, :health_provider])
      .order(date: :desc)

    # 2. Structure the data
    # # Since base_query is an ActiveRecord collection of ImagingReports, Rails (Ruby specifically) looks for a method inside ImagingReport Class (model)
    # base_query is an array of hashs
    return base_query.map(&:to_structured_data) unless query.present? && query.length > 2

    # Execute que search_query if there's a query.
    # Both terms from query must be present in ts_vector
    # We use simple configuration to make Postgres not to discard stop words like "de", "a", "o", "da", "do", "das", "dos"...
    search_query = query.split.map {|term| "#{term}:*"}.join(" & ") # :* Postgress Operator for pre-fixing match

    base_query
      .left_joins(:labels)
      .where(
        "(to_tsvector('simple', unaccent(imaging_reports.content)) ||
          to_tsvector('simple', unaccent(labels.name)) ||
          to_tsvector('simple', unaccent(imaging_methods.name))) @@
          to_tsquery('simple', unaccent(:query))",
        query: search_query
      )
      .distinct # Get just one result of ImagingReport (no matter how many labels)
      .map(&:to_structured_data)
  end

  # This method transforms each ActiveRecord ImagingReport collection into a structured hash.
  # Output example:
  #   {
  #     id: 1,
  #     content: "MRI scan result...",
  #     date: "2025-02-15",
  #     imaging_method: "MRI",
  #     labels: [{ id: 10, name: "Musculoskeletal" }, { id: 20, name: "Elbow" }],
  #     label_system: ["Musculoskeletal"],
  #     title: ["Elbow", "Sagittal Plane"]
  #   }

  def to_structured_data
    label_system = []
    title = []
    # Label is an ActiveRecord Label::ActiveRecord_Associations_CollectionProxy.
    # This is a proxy object that represents a collection of associated records.
    # It behaves like an array but also provides ActiveRecord querying methods.
    # It behaves like an array but is optimized for database interactions
    labels.each do |label|
      label.parents.each do |parent|
        case parent.name
        when "Sistema"
          label_system << label.name
        when "Parte", "Órgão"
          title[0] = label.name
        when "Plano sagittal"
          title[1] = label.name
        end
      end
    end
    title[1] = adjust_gender(title[0], title[1]) if title[0] && title[1]

    {
      id: id,
      content: content,
      date: date,
      imaging_method: imaging_method.name,
      labels: labels.map { |label| { id: label.id, name: label.name } }, # [:labels] will be an Array of hashs
      label_system: label_system,
      title: title,
      health_professional: health_professional,
      health_provider: health_provider,
      report_urls: image_urls("report"),
      image_urls: image_urls("image"),
      data_type: source.source_type.name
    }
  end

  private

  def image_urls(metadata)
    # Ensure you retrieve the files attached to the source
    # rails_blob_path generates a URL for the file, which can be used in the frontend.
    # only_path: true gives the relative URL (without the domain name), which is useful for rendering in your views
    report_image_urls = source.files
      .select { |file| file.blob.metadata["file_type"] == metadata }
      .map { |file| Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true) }
  end

  # Transforms Label "Direito" in "Direita" if Label title [0] is feminine.
  def adjust_gender (reference_word, target_word)
    exceptions = {
      "mão" => :feminine,
      "pé" => :masculine,
    }

    # The || operator returns the first truthy value it encounters.
    gender = exceptions[reference_word.downcase] || (reference_word.end_with?("o") ? :masculine : :feminine)

    if gender == :masculine
      return target_word
    elsif gender == :feminine
      target_word = target_word.gsub(/o$/, "a")
    end
  end

  def destroy_source
    source.destroy
  end
end

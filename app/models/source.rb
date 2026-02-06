class Source < ApplicationRecord
  belongs_to :human
  has_many :measures, dependent: :destroy
  belongs_to :source_type, optional: true



  # Override destroy to ensure source deletion is properly tracked
  # before_destroy callback does NOT guarantee it runs before the depedent measures are deleted after the callback runs.
  # Rails processes dependent: :destroy associations after before_destroy but before the source is actually destroyed
  # Therefore, instead of using the default before_destroy callback from the default destroy method, we use a custom destroy method that ensures the source is marked for deletion before the measures are destroyed.
  def destroy
    mark_source_for_deletion
    super
  ensure
    # Always executes regardless of success or failure
    # Runs even if an exception is raised during super
    # Prevents stale data from remaining in Thread.current
    clear_source_deletion_mark # Ensure cleanup even if there's an error.
  end


  has_many :imaging_reports, dependent: :destroy
  # Deleting a source deletes its respective imaging_reports
  # has_one :imaging_report, dependent: :destroy

  has_many_attached :files

  # Association with SourceType
  belongs_to :source_type, optional: true

  # Associations with HealthProfessional and HealthProvider
  belongs_to :health_professional, optional: true
  belongs_to :health_provider, optional: true

  # A source can be unit, batch or api
  # unit: health data was imported due to a single exam upload -> Default value
  # batch: When health data was imported due to a batch upload -> Common for first time blood exam upload
  # api: When health data was imported due to an API upload -> wearable data
  enum origin: { unit: 0, batch: 1, api: 2}




  def self.ransackable_associations(auth_object = nil)
    ["measures", "human", "source_type", "health_provider", "health_professional", "imaging_reports"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["source_type", "created_at", "id", "updated_at", "files_attachments_id", "files_blobs_id", "file_cont", "file", "origin"]
  end

  # Brings the first record date associated to source
  def date
    case source_type&.name
    when "Blood" then measures&.first&.date
    when "Bioimpedance" then measures&.first&.date
    when "Image" then imaging_reports&.first&.date
    else nil
    end
  end

  private

  def mark_source_for_deletion
    Thread.current[:sources_being_deleted] ||= []
    Thread.current[:sources_being_deleted] << self.id
    Rails.logger.info "====> Source #{self.id} marked for deletion. Thread.current[:sources_being_deleted]: #{Thread.current[:sources_being_deleted]}"
  end

  def clear_source_deletion_mark
    Thread.current[:sources_being_deleted]&.delete(self.id)
    Rails.logger.info "====> Source #{self.id} deletion mark cleared. Thread.current[:sources_being_deleted]: #{Thread.current[:sources_being_deleted]}"
  end

end

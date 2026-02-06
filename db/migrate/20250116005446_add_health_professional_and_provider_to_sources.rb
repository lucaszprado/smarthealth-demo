class AddHealthProfessionalAndProviderToSources < ActiveRecord::Migration[7.1]
  def change
    # Add health_professional_id with a foreign key
    add_reference :sources, :health_professional, foreign_key: true, null: true

    # Add health_provider_id with a foreign key
    add_reference :sources, :health_provider, foreign_key: true, null: true
  end
end

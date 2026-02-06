class Biomarker < ApplicationRecord
  has_many :synonyms
  has_many :measures
  has_many :biomarkers_ranges
  has_many :unit_factors
  has_many :categories, through: :measures
  has_many :units, through: :unit_factors
  has_many :label_assignments, as: :labelable, dependent: :destroy
  has_many :labels, through: :label_assignments

  # This class method. It's applied on the class all the time.
  def self.ransackable_associations(auth_object = nil)
    ["synonyms", "measures", "biomarkers_ranges", "unit_factors", "categories", "units", "label_assignments", "labels"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "external_ref", "id", "id_value", "name", "updated_at"]
  end

  # @!scope class
  # @!method with_distinct_pt_synonyms
  #   Returns a scope containing each biomarker exactly once, preferring its
  #   Portuguese ("PT") synonym if available, otherwise falling back to the biomarker's own name.
  #   Adds a computed column "sort_name" for sorting and display.
  #
  #   @return [ActiveRecord::Relation] a relation with each biomarker, and a "sort_name" column using PT synonym if present or biomarker name otherwise.
  #
  #   @example
  #     # Get all biomarkers (one per ID) with "sort_name" as PT synonym if available, else fallback to biomarker name
  #     Biomarker.with_distinct_pt_synonyms.each do |b|
  #       puts b.sort_name # Output: PT synonym name or biomarker name
  #     end
  scope :with_distinct_pt_synonyms, -> {
    left_joins(:synonyms) # Brings biomarkers w/ and w/o a synonym.
      .where("synonyms.language = 'PT' OR synonyms.id IS NULL")
      .includes(:synonyms)
      .select("DISTINCT ON (biomarkers.id) biomarkers.*, COALESCE(synonyms.name, biomarkers.name) AS sort_name")
      #.distinct -> distinct without proper control over which row wins can behave unpredictably in SQL
      # Because of it we moved it to the select statement
      .order(Arel.sql("biomarkers.id, COALESCE(synonyms.name, biomarkers.name)"))
      # .order(...) is required by DISTINCT ON, and must start with the same fields used in DISTINCT ON (...)
      # When you use DISTINCT ON (something) in PostgreSQL, the first part of the ORDER BY clause must exactly match the DISTINCT ON fields.
      #
      # Arel.sql tells Rails that it can trust this SQL. No SQL Injection.
      # Arel is a Ruby library used internally by Rails to build SQL queries
      # .oder method doesn't accept parameters, it accepts only column references.
      # Because of that we can't use the placeholder ?
      #
      #.reorder("sort_name")
      #.reorder(...) tells ActiveRecord/PostgreSQL how to actually order the final output
      # However reorder messed up how distinct works -> We need second query just to reorder.
  }


  scope :with_labels, -> {
    joins(:labels)
      .select("biomarkers.*, labels.name AS label_name")
      .order("labels.name")
  }

  scope :by_label, ->(label_name) {
    joins(:labels)
      .where(labels: {name: label_name})
  }



  # This query return a Partial Active Record relation.
  # Because of it it's not defined as a scope.
  def self.with_pt_synonyms_ordered_by_name
    from(with_distinct_pt_synonyms, :biomarkers).order("sort_name")
  end

  # Build ActiveRecord collection of measures with the latest measure per biomarker,
  # Build the Inner Query to select the latest measure per biomarker,
  # human_id: 1
  # birthdate: '1990-01-01'
  # gender: 'M'
  # source_type_names: ['Blood', 'Bioimpedance']
  # def self.last_measure_by_source(human_id, birthdate, gender, source_type_names)
  #   calculated_age_sql = "FLOOR(DATE_PART('year', AGE(DATE(measures.date), ?)))"

  #   inner_query = joins(measures: {source: :human}) # Inner joins from biomarkers <- measures <- source <- human
  #     .left_joins(:biomarkers_ranges, :unit_factors, :synonyms, measures: [:unit, source: :source_type])
  #     .includes(:biomarkers_ranges, :synonyms, :unit_factors, measures: [:unit, source: [:source_type, :health_professional, :health_provider]]) # includes are often best placed on the final query if possible, but might be needed here depending on usage.
  #     .where(sources: {human_id: human_id})
  #     .where(source_types: {name: source_type_names})
  #     .where("(unit_factors.biomarker_id = measures.biomarker_id AND unit_factors.unit_id = measures.unit_id) OR unit_factors.id IS NULL")
  #     # Allow records even if unit_factor doesn't exist
  #     .where("(biomarkers_ranges.biomarker_id = biomarkers.id AND biomarkers_ranges.age = #{calculated_age_sql} AND biomarkers_ranges.gender = ?) OR biomarkers_ranges.id IS NULL", birthdate, gender)
  #     # Allow records even if biomarker_range doesn't exist for the specific age/gender
  #     #
  #     # When you use .select(...) explicitly, ActiveRecord only includes the specified columns.
  #     # Select necessary columns, calculate display_name
  #     .select(<<~SQL)
  #       DISTINCT ON (measures.biomarker_id)
  #       measures.*,
  #       biomarkers.name,
  #       CASE WHEN synonyms.language = 'PT' THEN synonyms.name ELSE biomarkers.name END AS display_name,
  #       units.name AS unit_name,
  #       units.value_type AS unit_value_type,
  #       biomarkers_ranges.possible_min_value / unit_factors.factor AS same_unit_original_value_possible_min_value,
  #       biomarkers_ranges.possible_max_value / unit_factors.factor AS same_unit_original_value_possible_max_value,
  #       source_types.name AS source_type_name
  #     SQL
  #     #
  #     # Order strictly for DISTINCT
  #     # Order must have the same parameters as DISTINCT ON
  #     .order(Arel.sql("measures.biomarker_id,
  #                     measures.date DESC,
  #                     CASE WHEN synonyms.language = 'PT' THEN 0 ELSE 1 END,
  #                     synonyms.id DESC"))


  #   # Build the Outer Query to apply the final sorting on display_name
  #   # COLLATE \"pt_BR.UTF-8\" to treat Portuguese characters correctly
  #   # The alias 'biomarkers' allows referring to columns from the inner query.
  #   final_query = Biomarker.from(inner_query, :biomarkers)
  #                          .order(Arel.sql("biomarkers.display_name COLLATE \"pt_BR\" ASC"))

  #   # 3. Structure the data from the final sorted query
  #   results = final_query.map(&:attributes).map(&:symbolize_keys)

  #   # 4. Transform dataset for rendering (operates on the Array of Hashes)
  #   results = add_measure_text(results).yield_self{ |query| add_measure_status(query) }

  #   return results
  # end

  # def self.search_last_measure_by_source(human_id, birthdate, gender, query, source_type_names)
  #   calculated_age_sql = "FLOOR(DATE_PART('year', AGE(DATE(measures.date), ?)))"

  #   inner_query = joins(measures: {source: :human}) # Inner joins from biomarkers <- measures <- source <- human
  #     .left_joins(:biomarkers_ranges, :unit_factors, :synonyms, measures: [:unit, source: :source_type])
  #     .includes(:biomarkers_ranges, :synonyms, :unit_factors, measures: [:unit, source: [:source_type, :health_professional, :health_provider]])
  #     .where(sources: {human_id: human_id})
  #     .where(source_types: {name: source_type_names})
  #     # Allow records even if unit_factor doesn't exist
  #     .where("(unit_factors.biomarker_id = measures.biomarker_id AND unit_factors.unit_id = measures.unit_id) OR unit_factors.id IS NULL")
  #     # Allow records even if biomarker_range doesn't exist for the specific age/gender
  #     .where("(biomarkers_ranges.biomarker_id = biomarkers.id AND biomarkers_ranges.age = #{calculated_age_sql} AND biomarkers_ranges.gender = ?) OR biomarkers_ranges.id IS NULL", birthdate, gender)
  #     # Performs a full-text search on biomarker names and synonyms using PostgreSQL's text search capabilities
  #     #
  #     # @param query [String] The search query to match against biomarker names and synonyms
  #     #
  #     # The search uses the following PostgreSQL functions:
  #     # - to_tsvector(): Converts text to a searchable format, using Portuguese dictionary
  #     # - unaccent(): Removes accents from characters for accent-insensitive matching
  #     # - ||: Concatenates the tsvectors from synonyms.name and biomarkers.name
  #     # - @@: Text search match operator that returns true if tsvector matches tsquery
  #     # - to_tsquery(): Converts search terms to a format that can match against tsvector
  #     .where(
  #           "(to_tsvector('portuguese', unaccent(synonyms.name)) ||
  #             to_tsvector('portuguese', unaccent(biomarkers.name))) @@
  #             to_tsquery('portuguese', unaccent(:query))",
  #           query: query
  #         )
  #     #
  #     # When you use .select(...) explicitly, ActiveRecord only includes the specified columns.
  #     # Select necessary columns, calculate display_name
  #     .select(<<~SQL)
  #       DISTINCT ON (measures.biomarker_id)
  #       measures.*,
  #       biomarkers.name,
  #       CASE WHEN synonyms.language = 'PT' THEN synonyms.name ELSE biomarkers.name END AS display_name,
  #       units.name AS unit_name,
  #       units.value_type AS unit_value_type,
  #       biomarkers_ranges.possible_min_value / unit_factors.factor AS same_unit_original_value_possible_min_value,
  #       biomarkers_ranges.possible_max_value / unit_factors.factor AS same_unit_original_value_possible_max_value,
  #       source_types.name AS source_type_name
  #     SQL
  #     # Order strictly for DISTINCT ON correctness
  #     # measures.biomarker_id
  #     # 1. measures.date DESC (most recent first)
  #     # 2. Language priority (PT first)
  #     # 3. synonyms.id DESC (latest synonym)
  #     # All these criteria are applied in sequence when there are ties in the previous criteria.
  #     .order(Arel.sql("measures.biomarker_id,
  #                     measures.date DESC,
  #                     CASE WHEN synonyms.language = 'PT' THEN 0 ELSE 1 END,
  #                     synonyms.id DESC"))

  #  # 2. Build the Outer Query to apply the final sorting on display_name
  #   # COLLATE \"pt_BR.UTF-8\" to treat Portuguese characters correctly
  #   # The alias 'biomarkers' allows referring to columns from the inner query.

  #   # Build final query to sort results by display_name
  #   # - from(inner_query, :biomarkers): Uses inner_query as a subquery and aliases it as 'biomarkers'
  #   # - order: Sorts by display_name using Portuguese collation for proper character ordering
  #   #    COLLATE \"pt_BR.UTF-8\" to treat Portuguese characters correctly
  #   final_query = Biomarker.from(inner_query, :biomarkers)
  #                          .order(Arel.sql("biomarkers.display_name COLLATE \"pt_BR\" ASC"))

  #   # 3. Structure the data from the final sorted query
  #   # Convert ActiveRecord results to an array of hashes with symbol keys
  #   # 1. map(&:attributes) converts each ActiveRecord object to a hash with string keys
  #   # 2. map(&:symbolize_keys) converts those string keys to symbols
  #   # Example: {"name" => "Glucose"} becomes {name: "Glucose"}
  #   results = final_query.map(&:attributes).map(&:symbolize_keys)

  #   # 4. Transform dataset for rendering (operates on the Array of Hashes)
  #   # Processes the results by:
  #   # 1. Adding measure text (e.g. "Positivo"/"Negativo" for boolean values) via add_measure_text
  #   # 2. Then chains to add_measure_status which adds status indicators (e.g. "yellow" for out of range values)
  #   # yield_self allows chaining the result of add_measure_text into add_measure_status
  #   results = add_measure_text(results).yield_self{ |query| add_measure_status(query) }

  #   return results
  # end

  # Searches for the last measure of biomarkers for a given human, filtering by source type and optionally by biomarker IDs
  #
  # @param human_id [Integer] The ID of the human to search measures for
  # @param birthdate [String] The birthdate of the human in 'YYYY-MM-DD' format
  # @param gender [String] The gender of the human
  # @param source_type_names [Array<String>] Array of source type names to filter by (e.g. ["Blood", "Bioimpedance"])
  # @param query [String, nil] Optional search query to filter biomarkers by name
  # @param biomarker_ids [Array<Integer>, nil] Optional array of biomarker IDs to filter by
  #
  # @return [Array<Hash>] Array of hashes containing biomarker data with the following keys:
  #   - :id [Integer] The measure ID
  #   - :biomarker_id [Integer] The biomarker ID this measure belongs to
  #   - :source_id [Integer] The source ID this measure belongs to
  #   - :unit_id [Integer] The unit ID used for this measure
  #   - :value [Float] The measured value
  #   - :date [DateTime] When the measure was taken
  #   - :created_at [DateTime] When the record was created
  #   - :updated_at [DateTime] When the record was last updated
  #   - :name [String] The biomarker name
  #   - :display_name [String] The display name (PT synonym if available, otherwise name)
  #   - :unit_name [String] The unit name
  #   - :unit_value_type [Integer] The type of unit value
  #   - :same_unit_original_value_possible_min_value [Float] The minimum possible value converted to the same unit
  #   - :same_unit_original_value_possible_max_value [Float] The maximum possible value converted to the same unit
  #   - :source_type_name [String] The name of the source type
  #   - :measure_text [String] Text representation for boolean values ("Positivo"/"Negativo")
  #   - :measure_status [String] Status indicator ("yellow" for out of range, "green" for normal)
  def self.search_last_measure_by_source_for_ids(human_id:, birthdate:, gender:, source_type_names: [], query: nil, biomarker_ids: nil)
    calculated_age_sql = "FLOOR(DATE_PART('year', AGE(DATE(measures.date), '#{birthdate}')))"
    age = Human.find(human_id).age_at_measure(Date.today)

    inner_query = joins(measures: {source: :human}) # Inner joins from biomarkers <- measures <- source <- human
      # Allow records even if biomarker_range doesn't exist for the specific age/gender
      .joins("LEFT JOIN (
              SELECT DISTINCT ON (biomarker_id, age, gender)
              biomarkers_ranges.*
              FROM biomarkers_ranges
              ORDER BY biomarker_id, age, gender, updated_at DESC )
              biomarkers_ranges ON biomarkers_ranges.biomarker_id = biomarkers.id
              AND biomarkers_ranges.age = #{calculated_age_sql}
              AND biomarkers_ranges.gender = '#{gender}'") # joins doesn't support placeholders
      .left_joins(:unit_factors, :synonyms, measures: [:unit, source: :source_type])
      .includes(:synonyms, :unit_factors, measures: [:unit, source: [:source_type, :health_professional, :health_provider]])
      .where(sources: {human_id: human_id})
      .where(source_types: {name: source_type_names})
      .then { |scope| biomarker_ids.present? ? scope.where(id: biomarker_ids) : scope }
      # Allow records even if unit_factor doesn't exist
      .where("(unit_factors.biomarker_id = measures.biomarker_id
               AND unit_factors.unit_id = measures.unit_id)
               OR unit_factors.id IS NULL")
      # Only apply search if query is present
      .then do |scope|
        if query.present?
           # If synonyms.name is NULL, to_tsvector('simple', unaccent(NULL)) returns NULL.
           # In PostgreSQL, NULL || anything returns NULL.
           # So the entire left side becomes NULL.
           # COALESCE(synonyms.name, '') returns '' if synonyms.name is NULL.
          scope.where(
            "(to_tsvector('simple', unaccent(COALESCE(synonyms.name, ''))) ||
              to_tsvector('simple', unaccent(biomarkers.name))) @@
              to_tsquery('simple', unaccent(:query))",
            query: query # @@: Text search match operator that returns true if tsvector matches tsquery -> partial match comes from the FilterQueryService
          )
        else
          scope
        end
      end
      #
      # When you use .select(...) explicitly, ActiveRecord only includes the specified columns.
      # Select necessary columns, calculate display_name
      .select(<<~SQL)
        DISTINCT ON (measures.biomarker_id)
        measures.*,
        biomarkers.name,
        CASE WHEN synonyms.language = 'PT' THEN synonyms.name ELSE biomarkers.name END AS display_name,
        units.name AS unit_name,
        units.value_type AS unit_value_type,
        biomarkers_ranges.possible_min_value / unit_factors.factor AS same_unit_original_value_possible_min_value,
        biomarkers_ranges.possible_max_value / unit_factors.factor AS same_unit_original_value_possible_max_value,
        source_types.name AS source_type_name
      SQL
      # Arel allows to use raw SQL inside AR order method. Used when you have complex sorting criteria that can't be expressed in ActiveRecord.
      # 1. measures.date DESC (most recent first)
      # 2. Language priority (PT first)
      # 3. synonyms.id DESC (latest synonym)
      # All these criteria are applied in sequence when there are ties in the previous criteria.
      .order(Arel.sql("measures.biomarker_id,
                      measures.date DESC,
                      CASE WHEN synonyms.language = 'PT' THEN 0 ELSE 1 END,
                      synonyms.id DESC"))

   # 2. Build the Outer Query to apply the final sorting on display_name
    # COLLATE \"pt_BR.UTF-8\" to treat Portuguese characters correctly
    # The alias 'biomarkers' allows referring to columns from the inner query.

    # Build final query to sort results by display_name
    # - from(inner_query, :biomarkers): Uses inner_query as a subquery and aliases it as 'biomarkers'
    # - order: Sorts by display_name using Portuguese collation for proper character ordering
    #    COLLATE \"pt_BR.UTF-8\" to treat Portuguese characters correctly
    # The from() method creates a subquery using inner_query as the source table
    # and aliases it as 'biomarkers' for reference in subsequent clauses
    # This allows treating the complex inner_query results as a simple table
    # It doesn't matter which model we call from() on (Biomarker, Measure, etc) since we're
    # creating a new relation from a raw SQL subquery. The model class is ignored in this case.
    # The :biomarkers alias is needed so we can reference columns from this subquery
    # in subsequent clauses like the order() that follows.
    final_query = Biomarker.from(inner_query, :biomarkers)
                           .order(Arel.sql("biomarkers.display_name COLLATE \"pt_BR\" ASC"))


    # 3. Structure the data from the final sorted query
    # On this step the query runs. Before this line, ActiveRecord is just building up the query.
    # The .map operation forces the execution of the query, as it needs to iterate over the actual records.
    # Convert ActiveRecord results to an array of hashes with symbol keys
    # 1. map(&:attributes) converts each ActiveRecord object to a hash with string keys
    # 2. map(&:symbolize_keys) converts those string keys to symbols
    # Example: {"name" => "Glucose"} becomes {name: "Glucose"}
    results = final_query.map(&:attributes).map(&:symbolize_keys)

    # 4. Transform dataset for rendering (operates on the Array of Hashes)
    # Processes the results by:
    # 1. Adding measure text (e.g. "Positivo"/"Negativo" for boolean values) via add_measure_text
    # 2. Then chains to add_measure_status which adds status indicators (e.g. "yellow" for out of range values)
    # yield_self allows chaining the result of add_measure_text into add_measure_status
    results = add_measure_text(results).yield_self{ |query| add_measure_status(query) }

    return results
  end



  # Instance method
  # Return biomarker PT synonym or its name in english
  # Used in the measure model
  def title
    synonyms&.where(language: "PT")&.order(:id)&.last&.name || name
  end


  private

  # Removed sort_by_display_name as sorting is now handled by the database
  # def self.sort_by_display_name(collection)
  #   collection.sort_by do |biomarker|
  #     biomarker[:display_name]
  #   end
  # end

  def self.sort_by_synonym_or_name(collection)
    collection.sort_by do |biomarker|
      synonym = biomarker[:synonym_name]
      synonym ? biomarker[:synonym_name] : biomarker[:name]
    end
  end

  def self.add_measure_text(collection)
    collection.each do |biomarker|
      if biomarker[:unit_value_type] == 2
        case biomarker[:value]
        when 0
          biomarker[:measure_text] = "Negativo"
        else 1
          biomarker[:measure_text] = "Positivo"
        end
      else
        biomarker[:measure_text] = ""
      end
    end
  end

  def self.add_measure_status(collection)
    collection.each do |biomarker|
      if biomarker[:unit_value_type] == 1 && !biomarker[:same_unit_original_value_possible_max_value].nil?
        if biomarker[:original_value] > biomarker[:same_unit_original_value_possible_max_value]
          biomarker[:measure_status] = "yellow"
        elsif biomarker[:original_value] < biomarker[:same_unit_original_value_possible_min_value]
          biomarker[:measure_status] = "yellow"
        else
          biomarker[:measure_status] = "green"
        end
      else
        biomarker[:measure_status] = nil
      end
    end
  end

end

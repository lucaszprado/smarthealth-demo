class BiomarkersController < ApplicationController

  def index
    @human = Human.find(params[:human_id])

    # Get flat biomarkers from FilterQueryService
    @flat_biomarkers = FilterQueryService.new(@human, selection_criteria_params).call

    # Transform into sections using BiomarkerSectionsService
    @biomarker_sections = BiomarkerSectionsService.new.call(@flat_biomarkers)

    # Define search url
    @search_url = human_biomarkers_path(@human)

    # Define controller response (normal render vs AJAX response)
    respond_to do |format|
      format.html do
        # Check if this is a turbo-frame request (via query_ux parameter)
        case params[:query_ux]
          when 'transient-box'
            Rails.logger.info("Transient box flow (HTML)")
            # Render results even when query is empty to show initial list
            # This handles turbo-frame src requests which use Accept: text/html
            render partial: "biomarkers/search_results_selector",
                  locals: { biomarker_sections: @biomarker_sections },
                  formats: [:html]

          when 'fixed-box'
            Rails.logger.info("Fixed box flow (HTML)")
            render partial: "section_list",
                  locals: { human: @human, biomarker_sections: @biomarker_sections },
                  formats: [:html]

          else
            # Normal page render flow
            render :index
        end
      end

      format.text { # AJAX response flow

        case params[:query_ux]
          when 'transient-box'
            Rails.logger.info("Transient box flow (text)")
            # Render results even when query is empty to show initial list
            render partial: "biomarkers/search_results_selector",
                  locals: { biomarker_sections: @biomarker_sections },
                  formats: [:html]

          when 'fixed-box'
            Rails.logger.info("Fixed box flow (text)")
            render partial: "section_list",
                  locals: { human: @human, biomarker_sections: @biomarker_sections },
                  formats: [:html]

          else
            render partial: "section_list",
                  locals: { human: @human, biomarker_sections: @biomarker_sections },
                  formats: [:html]
        end
      }
    end
  end

  private

  def selection_criteria_params
    params.permit(:query, :query_ux, types: [], filters: [])
  end
end

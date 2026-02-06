require 'json'

class PagesController < ApplicationController
  # 1. Puxar 1 biomarker

  def home
    @biomarker_measures = {"2024-01-03" => 90, "2024-08-15" => 99, "2025-12-02" => 60}
    @biomarker_measures_json = @biomarker_measures.to_json
    @biomarker_upper_band = 85
    @biomarker_lower_band = 70

  end


  def about
  end


  def welcome
    # Renders app/views/pages/welcome.html.erb using the default application layout
  end

  def welcome_draft
    # Renders app/views/pages/welcome.html.erb using the default application layout
  end

  def testxlspx
    # Renders app/views/pages/testxlspx.html.erb using the default application layout
  end

  def tailwind
    # Renders app/views/pages/tailwind.html.erb using the default application layout
  end



end

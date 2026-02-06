# app/controllers/humans_controller.rb
class HumansController < ApplicationController
  def show
    @human = Human.find(params[:id])
    @skip_bootstrap_stylesheet = true  # Skip Bootstrap stylesheet for Tailwind-only page
  end
end

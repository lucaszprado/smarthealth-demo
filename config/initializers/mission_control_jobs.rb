# Configure mission_control-jobs authentication
Rails.application.config.to_prepare do
  MissionControl::Jobs::ApplicationController.class_eval do
    before_action :authenticate_admin_user!
  end
end

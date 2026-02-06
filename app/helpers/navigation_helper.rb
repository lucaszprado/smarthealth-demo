module NavigationHelper
  # Navigation helper to determine if a navbar item corresponds to the current page
  # Returns true if the current page matches the page identifier, false otherwise
  # Update :reports and :referral when controllers are created
  def nav_item_active?(page_identifier)
    case page_identifier
    when :human
      controller_name == 'humans' && action_name == 'show'
    when :reports
      controller_name == 'imaging_reports' || controller_name == 'measures'
    when :referral
      controller_name == 'pages' && action_name == 'testxlspx'
    else
      false
    end
  end

  # Helper to get active class for nav items
  # Example: nav_item_class(:profile) returns either:
  # - "" (when not active)
  # - "is-active" (when active)
  def nav_item_class(page_identifier)
    active_class = nav_item_active?(page_identifier) ? 'is-active' : ''
    active_class
  end
end

# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
# Pin all controllers from the app/javascript/controllers directory to a specifier prefixed with "controllers"

# Resolves to bootstrap.js in the vendor/javascript directory
# Bootstrap gem only brings scss files (which are already imported in application.scss), not the js files
pin "bootstrap", to: "bootstrap.js"
# pin "bootstrap", to: "https://ga.jspm.io/npm:bootstrap@5.1.3/dist/js/bootstrap.esm.js"

pin "@popperjs/core", to: "https://ga.jspm.io/npm:@popperjs/core@2.11.6/dist/esm/popper.js"

pin "chart.js", to: "https://ga.jspm.io/npm:chart.js@4.2.0/dist/chart.js"
pin "@kurkle/color", to: "https://ga.jspm.io/npm:@kurkle/color@0.3.2/dist/color.esm.js"


# chartjs-adapter-date-fns is an adapter that allows Chart.js to use date-fns for date manipulation and formatting.
# Since the adapter uses "date-fns" bare specifier, we need to pin it to the version of date-fns that the adapter uses.
pin "chartjs-adapter-date-fns", to: "https://ga.jspm.io/npm:chartjs-adapter-date-fns@3.0.0/dist/chartjs-adapter-date-fns.esm.js"
pin "date-fns", to: "https://ga.jspm.io/npm:date-fns@3.6.0/index.js"
pin "date-fns/locale/pt-BR", to: "https://esm.sh/date-fns@3.6.0/locale/pt-BR"

# Pin your helper modules so importmap can fingerprint them and generate correct URLs
# Instead of relative paths with .js, use the bare specifier that importmap knows:
# Key differences:
#   - No ../
#   - No .js
#   - Just the logical name "helpers/chart_utils" that you pinned.
pin_all_from "app/javascript/helpers", under: "helpers"
# This creates the following pins:
# pin "helpers/chart_utils",  to: "helpers/chart_utils.js"
# pin "helpers/chart_config", to: "helpers/chart_config.js"

# shadcn-rails Stimulus controllers
#   “When the browser sees import "shadcn",it should request the URL corresponding to the asset logical path shadcn/index.js.”
#   At render time, Rails emits something like:
#   <script type="importmap">
#   {
#     "imports": {
#       "shadcn": "/assets/shadcn/index-abc123.js"
#     }
#   }
#   </script>
#  But for that URL to exist…
#  Sprockets must have precompiled an asset with the logical path shadcn/index.js.
#  That’s where the manifest comes in.
#
#  In app/assets/config/manifest.js:
#  //= link shadcn/index.js
#
#  This means:
# “Sprockets: during assets:precompile, find the asset with logical path shadcn/index.js and emit it to public/assets, fingerprinted.”

pin "shadcn", to: "shadcn/index.js"
pin "stimulus-use" # @0.52.3
pin "@floating-ui/dom", to: "@floating-ui--dom.js" # @1.7.4
pin "@floating-ui/core", to: "@floating-ui--core.js" # @1.7.3
pin "@floating-ui/utils", to: "@floating-ui--utils.js" # @0.2.10
pin "@floating-ui/utils/dom", to: "@floating-ui--utils--dom.js" # @0.2.10

# Pin all shadcn controllers - shadcn/index.js uses relative imports that need to be resolved
# The gem's shadcn/index.js imports controllers using "./controllers/..." which doesn't work
# with importmap in production, so we need to explicitly pin each controller
pin "shadcn/controllers/accordion_controller", to: "shadcn/controllers/accordion_controller.js"
pin "shadcn/controllers/avatar_controller", to: "shadcn/controllers/avatar_controller.js"
pin "shadcn/controllers/base_menu_controller", to: "shadcn/controllers/base_menu_controller.js"
pin "shadcn/controllers/calendar_controller", to: "shadcn/controllers/calendar_controller.js"
pin "shadcn/controllers/carousel_controller", to: "shadcn/controllers/carousel_controller.js"
pin "shadcn/controllers/checkbox_controller", to: "shadcn/controllers/checkbox_controller.js"
pin "shadcn/controllers/collapsible_controller", to: "shadcn/controllers/collapsible_controller.js"
pin "shadcn/controllers/combobox_controller", to: "shadcn/controllers/combobox_controller.js"
pin "shadcn/controllers/command_controller", to: "shadcn/controllers/command_controller.js"
pin "shadcn/controllers/command_dialog_controller", to: "shadcn/controllers/command_dialog_controller.js"
pin "shadcn/controllers/context_menu_controller", to: "shadcn/controllers/context_menu_controller.js"
pin "shadcn/controllers/date_picker_controller", to: "shadcn/controllers/date_picker_controller.js"
pin "shadcn/controllers/dialog_controller", to: "shadcn/controllers/dialog_controller.js"
pin "shadcn/controllers/drawer_controller", to: "shadcn/controllers/drawer_controller.js"
pin "shadcn/controllers/dropdown_controller", to: "shadcn/controllers/dropdown_controller.js"
pin "shadcn/controllers/hover_card_controller", to: "shadcn/controllers/hover_card_controller.js"
pin "shadcn/controllers/input_otp_controller", to: "shadcn/controllers/input_otp_controller.js"
pin "shadcn/controllers/menubar_controller", to: "shadcn/controllers/menubar_controller.js"
pin "shadcn/controllers/navigation_menu_controller", to: "shadcn/controllers/navigation_menu_controller.js"
pin "shadcn/controllers/popover_controller", to: "shadcn/controllers/popover_controller.js"
pin "shadcn/controllers/radio_group_controller", to: "shadcn/controllers/radio_group_controller.js"
pin "shadcn/controllers/resizable_controller", to: "shadcn/controllers/resizable_controller.js"
pin "shadcn/controllers/scroll_area_controller", to: "shadcn/controllers/scroll_area_controller.js"
pin "shadcn/controllers/select_controller", to: "shadcn/controllers/select_controller.js"
pin "shadcn/controllers/sheet_controller", to: "shadcn/controllers/sheet_controller.js"
pin "shadcn/controllers/sidebar_controller", to: "shadcn/controllers/sidebar_controller.js"
pin "shadcn/controllers/slider_controller", to: "shadcn/controllers/slider_controller.js"
pin "shadcn/controllers/switch_controller", to: "shadcn/controllers/switch_controller.js"
pin "shadcn/controllers/tabs_controller", to: "shadcn/controllers/tabs_controller.js"
pin "shadcn/controllers/toast_controller", to: "shadcn/controllers/toast_controller.js"
pin "shadcn/controllers/toggle_controller", to: "shadcn/controllers/toggle_controller.js"
pin "shadcn/controllers/toggle_group_controller", to: "shadcn/controllers/toggle_group_controller.js"
pin "shadcn/controllers/tooltip_controller", to: "shadcn/controllers/tooltip_controller.js"

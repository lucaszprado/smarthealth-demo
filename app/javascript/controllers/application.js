import { Application } from "@hotwired/stimulus"


const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }


// Note: We're NOT loading all shadcn controllers via shadcn/index.js because:
// 1. shadcn/index.js uses relative imports (./controllers/...) which don't work with importmap
// 2. We only use a few shadcn controllers and have custom overrides for some (combobox, select)
// 3. Our custom controllers (combobox_controller, select_controller) are registered in controllers/index.js
// If you need additional shadcn controllers, you can import them individually from shadcn/controllers/...
// and register them manually, but be aware that they also use relative imports which may not work

// // Import and register shadcn-rails controllers
// import { registerShadcnControllers } from "shadcn"
// registerShadcnControllers(application)

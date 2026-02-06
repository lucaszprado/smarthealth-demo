import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="backdrop"
// Listens to toggle:opened and toggle:closed events (can be from same element or child elements)
export default class extends Controller {

  static targets = ["backdropElement"]

  showBackdrop() {
    if (this.hasBackdropElementTarget) {
      this.backdropElementTarget.classList.remove("hidden")
      document.body.classList.add("overflow-hidden")
    }

  }

  hideBackdrop() {
    if (this.hasBackdropElementTarget) {
      this.backdropElementTarget.classList.add("hidden")
      document.body.classList.remove("overflow-hidden")
    }
  }

  // Legacy method for direct action calls (can be removed if not used elsewhere)
  applyBackdrop() {
    this.showBackdrop()
  }
}

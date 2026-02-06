import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="modal-backdrop"
export default class extends Controller {

  static targets = ["panel", "backdrop"]


  connect() {
    document.addEventListener('keydown', this.handleKeydown.bind(this))
  }

  disconnect() {
    document.removeEventListener('keydown', this.handleKeydown.bind(this))
  }

  open() {
    this.panelTarget.classList.add('FiltersPanel--isOpen')
    document.body.classList.add('modal-open')
    // The modal-open class is typically used to prevent background scrolling when a modal is open.
    // It's a common pattern in web development to add this class to the body element to lock the page's scroll position while a modal dialog is displayed, preventing the user from scrolling the main content behind the modal.
  }

  close() {
    this.panelTarget.classList.remove('FiltersPanel--isOpen')
    document.body.classList.remove('modal-open')
  }

  // Close when clicking backdrop
  backdropClick(event) {
    if (event.target === this.backdropTarget) {
      this.close()
    }
  }

  // Close on ESC key
  handleKeydown(event) {
    if (event.key === 'Escape' && this.panelTarget.classList.contains('is-open')) {
      this.close()
    }
  }
}

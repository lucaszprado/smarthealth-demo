import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="scroll"
export default class extends Controller {
  static targets = ["messagesContainer", "messageContainer", "button"]
  static values = {
    autoScroll: { type: Boolean, default: true }
  }

  connect() {
    // Initial scroll to bottom
    // console.log("Scroll controller connected for element:", this.element.id)
    // console.log("Element content:", this.element.textContent)
    this.element.scrollIntoView({ behavior: 'smooth' }); // scroll to the bottom of the page
  }
}

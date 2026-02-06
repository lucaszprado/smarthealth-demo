import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="reset-form"
export default class extends Controller {
  static targets = ["form"]

  connect() {
  }

  reset() {
    const form = this.hasFormTarget ? this.formTarget : this.element
    form.reset()
  }
}

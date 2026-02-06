import { Controller } from "@hotwired/stimulus"
import { Tooltip } from "bootstrap"

// Connects to data-controller="tooltip"
export default class extends Controller {
  static targets = ["element"]

  connect() {
    // console.log("Tooltip controller connected");
    this.elementTargets.forEach((element) => {
      new Tooltip(element)
    })
  }
}

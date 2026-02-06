import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="toggle"
export default class extends Controller {
  static targets = ["desktopAffordance", "mobileAffordance", "toggleButton", "dropdownSelector"]

  toggleChanged() {
    // Only toggle on medium+ screens (768px+)
    // On mobile, the dropdown should remain hidden (do nothing)
    const isMediumOrLarger = window.innerWidth >= 768

    if (isMediumOrLarger) {
      // Toggle the 'hidden' class
      // When 'hidden' is removed, add 'block' to show it
      // When 'hidden' is added, remove 'block' to hide it
      if (this.desktopAffordanceTarget.classList.contains("hidden")) {
        this.desktopAffordanceTarget.classList.remove("hidden")
        this.desktopAffordanceTarget.classList.add("block")
        this.toggleButtonTarget.classList.add("bg-gray-300")
        this.dispatch("opened") // event type: "toggle:opened" - bubbles to backdrop on same element
        this.activateDropdownSelector() // Directly activate dropdown-selector controller

      } else {
        this.desktopAffordanceTarget.classList.add("hidden")
        this.desktopAffordanceTarget.classList.remove("block")
        this.toggleButtonTarget.classList.remove("bg-gray-300")
        this.dispatch("closed") // event type: "toggle:closed" - bubbles to backdrop on same element
      }
      // On mobile (< 768px), do nothing - element stays hidden
    } else {
      if (this.mobileAffordanceTarget.classList.contains("hidden")) {
        this.mobileAffordanceTarget.classList.remove("hidden")
        this.toggleButtonTarget.classList.add("bg-gray-300")
        this.dispatch("opened")
        this.activateDropdownSelector() // Directly activate dropdown-selector controller
      } else {
        // console.log("Flow to close mobile drawer component")
        this.mobileAffordanceTarget.classList.add("hidden")
        this.toggleButtonTarget.classList.remove("bg-gray-300")
        this.dispatch("closed")
      }
    }

  }

  /**
   * @function activateDropdownSelector
   * @description Activates the dropdown-selector controller by calling its activate method directly.
   * This is needed because events dispatched from parent elements don't bubble down to child elements.
   */
  activateDropdownSelector() {
    if (this.hasDropdownSelectorTarget) {
      const dropdownSelectorController = this.application.getControllerForElementAndIdentifier(
        this.dropdownSelectorTarget,
        "dropdown-selector"
      )
      if (dropdownSelectorController) {
        dropdownSelectorController.activate()
      }
    }
  }

}

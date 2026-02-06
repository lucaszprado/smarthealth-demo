import { Controller } from "@hotwired/stimulus"



/**
 * @class DropdownSelectorController
 * @extends Controller
 * @description Manages selection of items in a dropdown menu.
 * Handles adding/removing menu items, updating URL state, and refreshing turbo-frames.
 *
 * @example
 * // In your HTML template:
 * <div data-controller="dropdown-selector"
 *      data-dropdown-selector-params-name-value="biomarker_ids[]"
 *      data-dropdown-selector-frame-ids-value='["chart-frame", "selected-biomarkers"]'>
 *   <button data-action="click->dropdown-selector#add" data-menu-item-id="123">Add</button>
 *   <button data-action="click->dropdown-selector#remove" data-menu-item-id="123">×</button>
 *   <turbo-frame id="chart-frame">
 *     <!-- Frame content will be refreshed when items are added/removed -->
 *   </turbo-frame>
 *   <turbo-frame id="selected-biomarkers">
 *     <!-- Selected items will be refreshed when items are added/removed -->
 *   </turbo-frame>
 * </div>
 *
 * @values {String} paramsName - The URL parameter name to use.
 * @values {Array<String>} frameIds - Array of turbo-frame IDs to refresh.
 */


// Connects to data-controller="dropdown-selector"
export default class extends Controller {
  static targets = ["searchResultsContainer", "mobileClickableArea", "desktopClickableArea"]
  static values = {
    paramsName: String,
    frameIds: {type: Array, default: []}
  }

  connect() {
    this.active = false
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("click", this.handleClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside)
  }

  activate() {
    this.active = true
    // console.log("dropdown-selector controller activated")
  }

  /**
   * @function handleClickOutside
   * @description Handles clicks outside the search results container to close the dropdown
   * @param {Event} event - Click event from document
   */
  handleClickOutside(event) {
    // console.log("handleClickOutside active:",this.active)
    if (!this.active) return

    // Prevent closing when clicking inside the controller element
    // This prevents the dropdown from closing when clicking the toggle button
    // console.log("event.target:",event.target)
    if (this.element.contains(event.target)) return

    const clickableArea = this.mobileClickableAreaTarget || this.desktopClickableAreaTarget

    // Check if the click is inside the search results clickable area
    const clickedInsideClickableArea = clickableArea.contains(event.target)


    // If click is inside the clickable area, don't close
    if (clickedInsideClickableArea) return


    // console.log("toggle:request-close event will be dispatched")
    // If click is outside the results container and not on the input, close the dropdown
    this.element.dispatchEvent(
      new CustomEvent('toggle:request-close', { bubbles: true })
    )

    this.active = false

  }

  /**
   * @function closeDropdown
   * @description Closes clickable area where search results are displayed when clicked outside of it.
   */
  closeDropdown() {
    const clickableArea = this.mobileClickableAreaTarget || this.desktopClickableAreaTarget
    if (clickableArea) {
      this.mobileClickableAreaTarget.classList.add('hidden')
      this.desktopClickableAreaTarget.classList.add('hidden')
    }
  }

  /**
   * @function add
   * @description Adds an item to the selection and updates the frame to be refreshed.
   * @param {Event} event - Click event from "Add" button
   */

  add(event) {
    event.preventDefault()
    const menuItemId = event.currentTarget.dataset.menuItemId

    if (!menuItemId) return

    const currentIds = this.currentMenuItemIds()

    // Don't add if already selected
    if (currentIds.includes(menuItemId)) return

    // Add to selection
    currentIds.push(menuItemId)
    this.updateFrame(this.paramsNameValue, currentIds)


  }

  /**
   * @function remove
   * @description Removes a menu item from the selection and updates the frame to be refreshed.
   * @param {Event} event - Click event from remove (×) button
   */
  remove(event) {
    event.preventDefault()
    const menuItemId = event.currentTarget.dataset.menuItemId

    if (!menuItemId) return

    const currentIds = this.currentMenuItemIds().filter(id => id !== menuItemId)

    this.updateFrame(this.paramsNameValue, currentIds)
  }

  /**
   * @function updateFrame
   * @description Updates URL with new params and reloads all specified turbo-frames
   * @param {String} paramsName - name of the param to be updated
   * @param {Array<String>} menuItemIds - Array of menuItem IDs to display
   *
   * @example
   * paramsName: 'biomarker_ids[]'
   * menuItemIds: [1, 2, 3]
   * updateFrame('biomarker_ids[]', [1, 2, 3])
   */
  updateFrame(paramsName, menuItemIds) {
    const currentUrl = new URL(window.location)

    // Clear existing paramsName
    currentUrl.searchParams.delete(paramsName)

    // Add new menuItem_ids[]
    menuItemIds.forEach(id => {
      currentUrl.searchParams.append(paramsName, id)
    })

    // Update browser URL for shareability
    window.history.replaceState({}, "", currentUrl.toString())

    // Reload all specified turbo-frames
    this.frameIdsValue.forEach(frameId => {
      // First try to find all frames within the controller's scope
      // This handles cases where the same partial is rendered multiple times
      // (e.g., desktop and mobile panels with duplicate frame IDs)
      // We search within the controller element to ensure we update the correct instance
      const framesInScope = this.element.querySelectorAll(`turbo-frame#${frameId}`)

      // Update all frames found within the controller scope
      if (framesInScope.length > 0) {
        framesInScope.forEach(frame => {
          // Use Turbo's frame navigation API to reload the frame
          frame.src = currentUrl.toString()
        })
      } else {
        // If not found in controller scope, try document scope (for global frames like "chart-frame")
        const frame = document.getElementById(frameId)
        if (frame) {
          // Use Turbo's frame navigation API to reload the frame
          frame.src = currentUrl.toString()
        }
      }
    })
  }

  /**
   * @function currentMenuItemIds
   * @description Gets current menuItem_ids[] from the corresponding params in the URL
   * @return {Array<String>} menuItemIds - Array of menuItem IDs to be displayed
   *
   * @example
   * paramsName: 'biomarker_ids[]'
   * return: ["123", "456"]
   *    Considering URL:...?biomarker_ids[]=123&biomarker_ids[]=&biomarker_ids[]=456.
   */
  currentMenuItemIds() {
    const currentUrl = new URL(window.location)
    return currentUrl.searchParams.getAll(this.paramsNameValue).filter(Boolean)
  }
}

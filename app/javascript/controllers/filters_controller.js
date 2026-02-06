import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="filters"
export default class extends Controller {
  static targets = ["panel", "toggle", "affordance"]

  connect() {
    this.updateAffordanceBadge()
  }


  /*
   * @function toggleChanged
   * @description Handles state updates when filter toggles are changed
   * Triggered when a filter checkbox is toggled. Performs three key actions:
   * 1. Updates the URL to reflect current filter state via updateUrl()
   * 2. Updates the visual affordance badge showing active filters via updateAffordanceBadge()
   * 3. Reloads the biomarkers list to show filtered results via reloadBiomarkersList()
   */
  toggleChanged() {
    this.updateUrl()
    this.updateAffordanceBadge()
    this.reloadBiomarkersList()
  }

  updateUrl() {
    const currentUrl = new URL(window.location)
    const currentSearchParams = new URLSearchParams(window.location.search)

    // Returns an array of selected filters. Elements are checkbox values.
    const selectedFilters = this.toggleTargets
      .filter(toggle => toggle.checked)
      .map(toggle => toggle.value)

    // Update filters parameter
    currentUrl.searchParams.delete('filters[]')
    selectedFilters.forEach(filter => {
      currentUrl.searchParams.append('filters[]', filter)
    })

    // Preserve other params (query, types)
    if (currentSearchParams.has('query')) {
      currentUrl.searchParams.set('query', currentSearchParams.get('query'))
    }
    if (currentSearchParams.has('types[]')) {
      currentUrl.searchParams.delete('types[]')
      currentSearchParams.getAll('types[]').forEach(type => {
        currentUrl.searchParams.append('types[]', type)
      })
    }

    // Debug: log the URL before updating
    // console.log('Updating URL to:', currentUrl.toString())

    // Update URL without page reload
    // Updates the browser URL without triggering a page reload
    // This allows us to maintain filter state in the URL while staying on the same page

    // history.replaceState() updates the URL without triggering a page reload
    // - First param (null): No state object needed since we're just updating URL
    // - Second param (""): Empty title string (unused by most browsers)
    // - Third param: The new URL we want to show in the address bar
    window.history.replaceState(null, "", currentUrl.toString())

  }

   /**
   * Reloads the biomarkers list frame with the current URL
   * This method updates the biomarkers list content when filters are changed
   * by setting the src attribute of the frame to the current window location
   * When you set the src attribute on a <turbo-frame>, Turbo automatically:
   * - Intercepts this change
   * - Makes an AJAX request to the URL
   * - Looks for a matching <turbo-frame> in the response
   * - Replaces the frame content
   */
  reloadBiomarkersList() {
    const frame = document.getElementById('biomarkers-list')
    if (frame) {
      // console.log('Reloading frame with URL:', window.location.href)
      frame.setAttribute('src', window.location.href)
    }
  }

  updateAffordanceBadge() {
    const activeFilters = this.toggleTargets.filter(toggle => toggle.checked).length
    const badge = this.affordanceTarget.querySelector('.FiltersPanel-badge') //it will store the DOM element corresponding to the <span> element that has the class FiltersPanel-badge, which is shown in biomarkers/index.html.erb as the badge displaying the number of active fil

    if (activeFilters > 0) {
      if (badge) {
        badge.textContent = activeFilters
      } else {
        const newBadge = document.createElement('span')
        newBadge.className = 'position-absolute translate-middle badge rounded-pill u-background--blueBrandNight FiltersPanel-badge'
        newBadge.textContent = activeFilters
        this.affordanceTarget.appendChild(newBadge)
      }
    } else if (badge) {
        badge.remove()
    }
  }

}

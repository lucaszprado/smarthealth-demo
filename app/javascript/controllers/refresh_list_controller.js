import { Controller } from "@hotwired/stimulus"

/**
 * @class RefreshListController
 * @extends Controller
 * @description A Stimulus controller that handles real-time refresh on lists with URL state management.
 * It searches/filters biomarkers to display a list
 * Search-as-you-type (filters display)
 * Preserves filters[] and types[] params
 * Updates a biomarkers list turbo-frame
 * Uses Turbo.visit() for proper history management
 *
 * @example
 * // In your HTML template:
 * <div data-controller="refresh-list">
 *   <form data-refresh-list-target="form">
 *     <input data-refresh-list-target="searchInput" data-action="keyup->refresh-list#update">
 *   </form>
 *   <div data-refresh-list-target="list">
 *     <!-- List content here -->
 *   </div>
 * </div>
 *
 * @targets {HTMLFormElement} form - The search form element
 * @targets {HTMLElement} list - The container element that will be updated with search results
 * @targets {HTMLInputElement} searchInput - The search input field
 */
export default class extends Controller {
  static targets = [ "form", "list", "searchInput" ]

  /**
   * @function update
   * @description Updates the list content based on search input while preserving URL query parameters
   * Triggered on every keyup event in the search input field
   * Builds the URL to be fetched by the server after the form is submitted
   * Manually fetches the search URL and updates the list content
   */
  update() {
    // Clear results immediately if search input is empty

    const queryValue = this.searchInputTarget.value.trim()
    const formData = new FormData(this.formTarget)
    const queryUx = formData.get('query_ux') || 'fixed-box'
    // if (queryValue === '') {
    //   this.listTarget.innerHTML = ''
    //   // Update URL to remove query parameter
    //   const currentUrl = new URL(window.location)
    //   currentUrl.searchParams.delete('query')
    //   window.history.replaceState(null, "", currentUrl.toString())
    //   return
    // }

    // Build URL preserving current filters and types
    // Example: /humans/123/imaging_reports?query=chest&filters[]=type1&filters[]=type2
    const currentUrl = new URL(window.location)
    const searchUrl = new URL(this.formTarget.action) //this.formTarget.action is the URL fetched by the search form - e.g. humans/3/biomarkers

    // Add query parameters to the search url reading form input value
    searchUrl.searchParams.set('query', queryValue)

    // Add other form fields to the search url
    for (const [key, value] of formData.entries()) {
      if (key !== 'query') { // query is already set above
        if (key.endsWith('[]')) {
          // Handle array parameters (e.g., filters[], types[])
          searchUrl.searchParams.append(key, value)
        } else {
          // Handle regular parameters (e.g., simple_results)
          searchUrl.searchParams.set(key, value)
        }
      }
    }

    // Add filter and type parameters from the current url to the search url
    if (currentUrl.searchParams.has('filters[]')) {
      currentUrl.searchParams.getAll('filters[]').forEach(filter => {
        searchUrl.searchParams.append('filters[]', filter)
      })
    }
    if (currentUrl.searchParams.has('types[]')) {
      currentUrl.searchParams.getAll('types[]').forEach(type => {
        searchUrl.searchParams.append('types[]', type)
      })
    }

    // Update browser history object to replace the current URL with the new search URL
    if (queryUx === 'fixed-box') {
      if (queryValue === '') {
        currentUrl.searchParams.delete('query')
      } else {
        currentUrl.searchParams.set('query', queryValue)
      }

      window.history.replaceState(null, "", currentUrl.toString())
    }

    // Fetch the searchUrl from the server
    fetch(searchUrl.toString(), {headers: {"Accept": "text/plain"}})
      .then(response => response.text())
      .then((data) => {
       //  console.log(data)
        this.listTarget.innerHTML = data
      })

    // Use Turbo's visit() for proper history management
    // This automatically updates the URL and handles browser history
    // visit(searchUrl.toString(), { action: "replace" })
    // Note: No need for manual fetch since visit() handles the request
    // The turbo-frame will automatically update with the response
    // Turbo.visit(searchUrl.toString(), {
    //   action: "replace",
    //   frame: this.listTarget.id // assuming listTarget is the <turbo-frame>
    // })
  }

  /**
   * @function preventSubmit
   * @description Prevents the default form submission to keep interactions within the Turbo frame
   * @param {SubmitEvent} event
   */
  preventSubmit(event) {
    event.preventDefault()
  }
}

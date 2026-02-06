import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  static values = {humanId: String}

  /*
   * Handles navigation back to the previous page or human profile
   * @method goBack
   * @description If there is a previous page from the same domain, navigates back while preserving URL parameters.
   *             Otherwise, redirects to the human's profile page as a fallback.
   * Note: link_to helper doesn't preserve URL parameters.
   * @returns {void}
   */
  oldGoBack() {
    // Check if there's a previous page from the same domain
    if (document.referrer && document.referrer.includes(window.location.origin)) {
      // Go back to the previous page (preserves all URL parameters)
      history.back()
    } else {
      // Fallback: navigate to the human page
      window.location.href = `/humans/${this.humanIdValue}`
    }
  }

  goBack() {
    const sameOriginReferrer =
      document.referrer && document.referrer.startsWith(window.location.origin)

    if (sameOriginReferrer) {
      // Force Turbo to do a fresh GET to the referrer URL
      Turbo.visit(document.referrer, { action: "replace" })
    } else {
      // Fallback: go to the human profile
      Turbo.visit(`/humans/${this.humanIdValue}`, { action: "replace" })
    }
  }
}

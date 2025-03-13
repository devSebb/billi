import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    direction: { type: String, default: "asc" },
    currentSort: String
  }

  connect() {
    // Initialize sort indicators
    this.updateSortIndicators()
  }

  sort(event) {
    const column = event.currentTarget.dataset.sortColumn
    const currentUrl = new URL(window.location.href)
    const params = new URLSearchParams(currentUrl.search)

    // Toggle direction if clicking the same column
    if (column === this.currentSortValue) {
      this.directionValue = this.directionValue === "asc" ? "desc" : "asc"
    } else {
      this.directionValue = "asc"
    }

    this.currentSortValue = column

    // Update URL parameters
    params.set('sort', column)
    params.set('direction', this.directionValue)
    params.delete('page')

    // Update URL and reload content
    Turbo.visit(`${window.location.pathname}?${params.toString()}`)
  }

  updateSortIndicators() {
    const currentUrl = new URL(window.location.href)
    const params = new URLSearchParams(currentUrl.search)
    this.currentSortValue = params.get('sort') || 'transaction_date'
    this.directionValue = params.get('direction') || 'desc'
  }
}

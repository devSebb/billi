import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    param: String
  }

  applyFilter(event) {
    const currentUrl = new URL(window.location.href)
    const params = new URLSearchParams(currentUrl.search)

    // Clear page parameter to reset pagination when filtering
    params.delete('page')

    if (event.target.value) {
      params.set(event.target.dataset.filterParam, event.target.value)
    } else {
      params.delete(event.target.dataset.filterParam)
    }

    // Update URL and reload content
    Turbo.visit(`${window.location.pathname}?${params.toString()}`)
  }
}

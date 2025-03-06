import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  applySort(event) {
    const currentUrl = new URL(window.location.href)
    const params = new URLSearchParams(currentUrl.search)

    // Update sort parameter
    params.set('sort', event.target.value)

    // Reset to first page when sorting changes
    params.delete('page')

    // Update URL and reload content
    Turbo.visit(`${window.location.pathname}?${params.toString()}`)
  }
}

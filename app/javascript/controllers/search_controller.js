import { Controller } from "@hotwired/stimulus"
import debounce from "lodash/debounce"

export default class extends Controller {
  static targets = ["input"]

  initialize() {
    this.debouncedSearch = debounce(this.performSearch.bind(this), 300)
  }

  perform() {
    this.debouncedSearch()
  }

  performSearch() {
    const currentUrl = new URL(window.location.href)
    const params = new URLSearchParams(currentUrl.search)
    const query = this.inputTarget.value.trim()

    if (query) {
      params.set('query', query)
    } else {
      params.delete('query')
    }

    // Reset to first page when searching
    params.delete('page')

    // Preserve existing sort parameters
    const sortParam = params.get('sort')
    const directionParam = params.get('direction')

    if (sortParam) params.set('sort', sortParam)
    if (directionParam) params.set('direction', directionParam)

    Turbo.visit(`${window.location.pathname}?${params.toString()}`)
  }

  // Optional: Clear search when pressing Escape
  disconnect() {
    if (this.debouncedSearch) {
      this.debouncedSearch.cancel()
    }
  }

  clearSearch(event) {
    this.inputTarget.value = ""
    this.performSearch()
  }
}

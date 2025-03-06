import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "arrow"]

  connect() {
    // Check localStorage for saved state
    const isOpen = localStorage.getItem('transactionsTableOpen') === 'true'
    if (isOpen) {
      this.open()
    }
  }

  toggle() {
    if (this.contentTarget.classList.contains("max-h-0")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.contentTarget.classList.remove("max-h-0")
    this.contentTarget.classList.add("max-h-[2000px]")
    this.arrowTarget.classList.add("rotate-180")
    localStorage.setItem('transactionsTableOpen', 'true')
  }

  close() {
    this.contentTarget.classList.add("max-h-0")
    this.contentTarget.classList.remove("max-h-[2000px]")
    this.arrowTarget.classList.remove("rotate-180")
    localStorage.setItem('transactionsTableOpen', 'false')
  }
}

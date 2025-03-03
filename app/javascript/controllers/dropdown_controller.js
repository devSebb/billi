import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "arrow"]

  toggle() {
    const content = this.contentTarget
    const arrow = this.arrowTarget

    if (content.style.maxHeight === "0px" || !content.style.maxHeight) {
      content.style.maxHeight = `${content.scrollHeight}px`
      arrow.style.transform = "rotate(180deg)"
    } else {
      content.style.maxHeight = "0px"
      arrow.style.transform = "rotate(0deg)"
    }
  }
}

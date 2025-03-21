import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.timeout = null
  }

  perform() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      const query = this.inputTarget.value
      const url = new URL(window.location)
      url.searchParams.set("query", query)

      Turbo.visit(url, {
        frame: "transactions-table",
        action: "replace"
      })
    }, 300)
  }

  clear() {
    this.inputTarget.value = ""
    this.perform()
  }
}

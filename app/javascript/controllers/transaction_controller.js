import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  connect() {
    console.log("Transaction controller connected")
  }

  edit(event) {
    event.preventDefault()
    const transactionId = event.currentTarget.dataset.transactionId
    console.log("Edit clicked for transaction:", transactionId)

    // Fetch the edit form via Turbo Stream
    fetch(`/transactions/${transactionId}/edit`, {
      headers: {
        Accept: "text/vnd.turbo-stream.html",
        "X-Requested-With": "XMLHttpRequest"
      }
    }).then(response => response.text())
      .then(html => {
        // First render the stream
        Turbo.renderStreamMessage(html)

        // Wait for DOM to update
        setTimeout(() => {
          const modal = document.getElementById('edit-transaction-modal-1')
          if (modal instanceof HTMLDialogElement) {
            modal.showModal()
          } else {
            console.error("Modal element not found or is not a dialog element")
          }
        }, 400)
      })
      .catch(error => console.error("Error fetching modal:", error))
  }

  closeModal() {
    const modal = document.getElementById('edit-transaction-modal-1')
    if (modal instanceof HTMLDialogElement) {
      modal.close()
    }
  }
}

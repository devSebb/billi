import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  async openLink(event) {
    event.preventDefault()

    try {
      // Get link token from our backend
      const response = await fetch('/plaid/create_link_token', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector("[name='csrf-token']").content
        }
      })
      const { link_token } = await response.json()

      // Load Plaid Link
      const { open } = await window.Plaid.create({
        token: link_token,
        onSuccess: async (public_token, metadata) => {
          // Exchange public token
          await fetch('/plaid/exchange_public_token', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'X-CSRF-Token': document.querySelector("[name='csrf-token']").content
            },
            body: JSON.stringify({ public_token })
          })

          // Reload page to show new transactions
          window.location.reload()
        },
        onExit: (err, metadata) => {
          if (err != null) console.error(err)
        },
      })
      open()
    } catch (error) {
      console.error('Error:', error)
    }
  }
}

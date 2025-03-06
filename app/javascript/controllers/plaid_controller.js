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

  async handleSandboxConnection(event) {
    event.preventDefault()

    try {
      // Get both link_token and public_token from sandbox endpoint
      const tokenResponse = await fetch('/plaid/sandbox_public_token', {
        method: 'POST',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      })

      if (!tokenResponse.ok) {
        const errorData = await tokenResponse.json()
        throw new Error(errorData.error || 'Failed to get sandbox tokens')
      }

      const { link_token, public_token } = await tokenResponse.json()

      // Exchange the public_token for an access_token
      const exchangeResponse = await fetch('/plaid/exchange_public_token', {
        method: 'POST',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ public_token: public_token })
      })

      if (!exchangeResponse.ok) {
        const errorData = await exchangeResponse.json()
        throw new Error(errorData.error || 'Failed to exchange public token')
      }

      const result = await exchangeResponse.json()
      if (result.success) {
        // Reload the page to show the new transactions
        window.location.reload()
      } else {
        throw new Error('Failed to process exchange response')
      }
    } catch (error) {
      console.error('Error connecting to Plaid:', error)
      alert('Failed to connect to Plaid: ' + error.message)
    }
  }
}

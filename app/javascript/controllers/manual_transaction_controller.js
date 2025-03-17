import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "modal",
    "expenseRadio",
    "incomeRadio",
    "amountField",
    "expenseCategories",
    "incomeCategories",
    "selectedCategory",
    "categoryField"
  ]

  connect() {
    this.updateCategoryVisibility()
  }

  showModal() {
    this.modalTarget.showModal()
  }

  closeModal() {
    this.modalTarget.close()
  }

  updateCategoryVisibility() {
    if (this.expenseRadioTarget.checked) {
      this.expenseCategoriesTarget.classList.remove('hidden')
      this.incomeCategoriesTarget.classList.add('hidden')
    } else if (this.incomeRadioTarget.checked) {
      this.expenseCategoriesTarget.classList.add('hidden')
      this.incomeCategoriesTarget.classList.remove('hidden')
    }
  }

  handleSubmit(event) {
    event.preventDefault()
    let amount = parseFloat(this.amountFieldTarget.value)
    amount = Math.abs(amount)

    if (this.incomeRadioTarget.checked) {
      this.amountFieldTarget.value = (amount * -1)
    } else {
      this.amountFieldTarget.value = amount
    }

    event.target.submit()
  }

  selectCategory(event) {
    const category = event.currentTarget.textContent
    this.selectedCategoryTarget.textContent = category
    this.categoryFieldTarget.value = category
  }
}

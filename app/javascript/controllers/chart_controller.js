import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["barChart", "doughnutChart", "barGroupBy", "barAggregate", "doughnutGroupBy", "doughnutTotal"]

  connect() {
    // Wait for Chart.js to load
    this.loadChartJs().then(() => {
      this.initializeCharts()
    })
  }

  disconnect() {
    this.cleanup()
  }

  cleanup() {
    if (this.barChart) {
      this.barChart.destroy()
      this.barChart = null
    }
    if (this.doughnutChart) {
      this.doughnutChart.destroy()
      this.doughnutChart = null
    }
  }

  async loadChartJs() {
    if (typeof Chart !== 'undefined') return

    return new Promise((resolve) => {
      const script = document.createElement('script')
      script.src = 'https://cdn.jsdelivr.net/npm/chart.js'
      script.onload = () => resolve()
      document.head.appendChild(script)
    })
  }

  initializeCharts() {
    this.cleanup() // Clean up any existing charts first

    if (this.hasBarChartTarget) {
      this.initializeBarChart()
    }
    if (this.hasDoughnutChartTarget) {
      this.initializeDoughnutChart()
    }
  }

  initializeBarChart() {
    if (this.hasBarGroupByTarget) {
      this.barGroupByTarget.addEventListener('change', this.handleBarChartChange.bind(this))
    }
    if (this.hasBarAggregateTarget) {
      this.barAggregateTarget.addEventListener('change', this.handleBarChartChange.bind(this))
    }
    this.updateBarChart()
  }

  initializeDoughnutChart() {
    if (this.hasDoughnutGroupByTarget) {
      this.doughnutGroupByTarget.addEventListener('change', this.handleDoughnutChartChange.bind(this))
    }
    this.updateDoughnutChart()
  }

  handleBarChartChange() {
    this.updateBarChart()
  }

  handleDoughnutChartChange() {
    this.updateDoughnutChart()
  }

  async updateBarChart() {
    if (!this.hasBarChartTarget) return

    try {
      const groupBy = this.hasBarGroupByTarget ? this.barGroupByTarget.value : 'category'
      const aggregate = this.hasBarAggregateTarget ? this.barAggregateTarget.value : 'sum'

      const response = await fetch(`/transactions/chart_data?group_by=${groupBy}&aggregate=${aggregate}`)
      const data = await response.json()

      if (this.barChart) {
        this.barChart.destroy()
      }

      const ctx = this.barChartTarget.getContext('2d')
      this.barChart = new Chart(ctx, {
        type: 'bar',
        data: {
          labels: data.labels,
          datasets: [{
            label: `${aggregate.charAt(0).toUpperCase() + aggregate.slice(1)} by ${groupBy}`,
            data: data.values,
            backgroundColor: 'rgba(79, 70, 229, 0.2)',
            borderColor: '#4F46E5',
            borderWidth: 1,
            borderRadius: 4,
            maxBarThickness: 50
          }]
        },
        options: this.getBarChartOptions(aggregate)
      })
    } catch (error) {
      console.error('Error updating bar chart:', error)
    }
  }

  async updateDoughnutChart() {
    if (!this.hasDoughnutChartTarget) return

    try {
      const groupBy = this.hasDoughnutGroupByTarget ? this.doughnutGroupByTarget.value : 'category'

      const response = await fetch(`/transactions/chart_data?group_by=${groupBy}&aggregate=sum`)
      const data = await response.json()

      if (this.doughnutChart) {
        this.doughnutChart.destroy()
      }

      const total = data.values.reduce((a, b) => Number(a) + Number(b), 0)
      if (this.hasDoughnutTotalTarget) {
        this.doughnutTotalTarget.textContent = this.formatCurrency(total)
      }

      const ctx = this.doughnutChartTarget.getContext('2d')
      this.doughnutChart = new Chart(ctx, {
        type: 'doughnut',
        data: {
          labels: data.labels,
          datasets: [{
            data: data.values,
            backgroundColor: this.getChartColors().map(color => `${color}33`),
            borderColor: this.getChartColors(),
            borderWidth: 2,
            hoverOffset: 8
          }]
        },
        options: this.getDoughnutChartOptions(total)
      })
    } catch (error) {
      console.error('Error updating doughnut chart:', error)
    }
  }

  getBarChartOptions(aggregate) {
    return {
      maintainAspectRatio: false,
      responsive: true,
      scales: {
        y: {
          beginAtZero: true,
          ticks: {
            callback: (value) => aggregate === 'count' ? value : this.formatCurrency(value)
          }
        }
      },
      plugins: {
        legend: { display: false }
      }
    }
  }

  getDoughnutChartOptions(total) {
    return {
      maintainAspectRatio: false,
      responsive: true,
      cutout: '65%',
      plugins: {
        legend: {
          position: 'bottom',
          labels: { font: { size: 12 } }
        }
      }
    }
  }

  getChartColors() {
    return [
      '#4F46E5',
      '#6EE7B7',
      '#F87171',
      '#FBBF24',
      '#34D399',
      '#60A5FA'
    ]
  }

  formatCurrency(value) {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(value)
  }
}

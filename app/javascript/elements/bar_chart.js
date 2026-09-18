export default class extends HTMLElement {
  static observedAttributes = ['data-labels', 'data-datasets']

  connectedCallback () {
    this.initChart()
  }

  disconnectedCallback () {
    if (this.chartInstance) {
      this.chartInstance.destroy()
      this.chartInstance = null
    }
  }

  attributeChangedCallback (_, oldValue, newValue) {
    if (!this.chartInstance || oldValue === newValue) return

    this.chartInstance.data.labels = JSON.parse(this.dataset.labels || '[]')
    this.chartInstance.data.datasets = JSON.parse(this.dataset.datasets || '[]')

    this.chartInstance.update()
  }

  async initChart () {
    const { default: Chart } = await import(/* webpackChunkName: "chartjs" */ 'chart.js/auto')

    const canvas = this.querySelector('canvas')

    const ctx = canvas.getContext('2d')

    this.chartInstance = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: JSON.parse(this.dataset.labels || '[]'),
        datasets: JSON.parse(this.dataset.datasets || '[]')
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        animation: false,
        scales: {
          y: {
            beginAtZero: true,
            grace: '20%',
            ticks: {
              precision: 0
            }
          }
        },
        plugins: {
          legend: {
            display: false
          }
        }
      }
    })
  }
}

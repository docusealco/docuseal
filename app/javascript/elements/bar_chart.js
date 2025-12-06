export default class extends HTMLElement {
  connectedCallback () {
    this.chartLabels = JSON.parse(this.dataset.labels || '[]')
    this.chartDatasets = JSON.parse(this.dataset.datasets || '[]')

    this.initChart()
  }

  disconnectedCallback () {
    if (this.chartInstance) {
      this.chartInstance.destroy()
      this.chartInstance = null
    }
  }

  async initChart () {
    const { default: Chart } = await import(/* webpackChunkName: "chartjs" */ 'chart.js/auto')

    const canvas = this.querySelector('canvas')

    const ctx = canvas.getContext('2d')

    this.chartInstance = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: this.chartLabels,
        datasets: this.chartDatasets
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

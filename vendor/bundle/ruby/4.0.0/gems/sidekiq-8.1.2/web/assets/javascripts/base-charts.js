if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
  Chart.defaults.borderColor = "#333";
  Chart.defaults.color = "#aaa";
  // Chart.defaults.borderColor = "oklch(22% 0.01 256)";
  // Chart.defaults.color = "oklch(65% 0.01 256)";
}

class Colors {
  constructor() {
    this.assignments = {};
    if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
      this.light = "65%";
      this.chroma = "0.15";
    } else {
      this.light = "48%";
      this.chroma = "0.2";
    }
    this.success = "oklch(" + this.light + " " + this.chroma + " 179)";
    this.failure = "oklch(" + this.light + " " + this.chroma + " 29)";
    this.fallback = "oklch(" + this.light + " 0.02 269)";
    this.primary = "oklch(" + this.light + " " + this.chroma + " 269)";
    this.available = [
      "oklch(" + this.light + " " + this.chroma + " 256)",
      "oklch(" + this.light + " " + this.chroma + " 196)",
      "oklch(" + this.light + " " + this.chroma + " 46)",
      "oklch(" + this.light + " " + this.chroma + " 316)",
      "oklch(" + this.light + " " + this.chroma + " 106)",
      "oklch(" + this.light + " " + this.chroma + " 226)",
      "oklch(" + this.light + " " + this.chroma + " 136)",
      "oklch(" + this.light + " 0.02 269)",
      "oklch(" + this.light + " " + this.chroma + " 286)",
      "oklch(" + this.light + " " + this.chroma + " 16)",
    ];
  }

  checkOut(assignee) {
    const color =
      this.assignments[assignee] || this.available.shift() || this.fallback;
    this.assignments[assignee] = color;
    return color;
  }

  checkIn(assignee) {
    const color = this.assignments[assignee];
    delete this.assignments[assignee];

    if (color && color != this.fallback) {
      this.available.unshift(color);
    }
  }
}

class BaseChart {
  constructor(el, options) {
    this.el = el;
    this.options = options;
    this.colors = new Colors();
  }

  init() {
    this.chart = new Chart(this.el, {
      type: this.options.chartType,
      data: { labels: this.options.labels, datasets: this.datasets },
      options: this.chartOptions,
    });
  }

  update() {
    this.chart.options = this.chartOptions;
    this.chart.update();
  }

  get chartOptions() {
    let chartOptions = {
      interaction: {
        mode: "nearest",
        axis: "x",
        intersect: false,
      },
      scales: {
        x: {
          ticks: {
            autoSkipPadding: 10,
          },
        },
      },
      plugins: {
        legend: {
          display: false,
        },
        annotation: {
          annotations: {},
        },
        tooltip: {
          animation: false,
        },
      },
    };

    if (this.options.marks) {
      if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
        this.Borderlight = "30%";
      } else {
        this.Borderlight = "65%";
      }

      this.options.marks.forEach(([bucket, label], i) => {
        chartOptions.plugins.annotation.annotations[`deploy-${i}`] = {
          type: "line",
          xMin: bucket,
          xMax: bucket,
          borderColor: "oklch(" + this.Borderlight + " 0.01 256)",
          borderWidth: 2,
        };
      });
    }

    return chartOptions;
  }
}

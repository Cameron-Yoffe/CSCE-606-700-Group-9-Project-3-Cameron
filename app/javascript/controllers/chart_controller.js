import { Controller } from "@hotwired/stimulus"
import {
  ArcElement,
  BarController,
  BarElement,
  CategoryScale,
  Chart,
  Legend,
  LinearScale,
  Title,
  Tooltip
} from "chart.js"

Chart.register(BarController, BarElement, CategoryScale, LinearScale, ArcElement, Legend, Title, Tooltip)

export default class extends Controller {
  static values = {
    data: Object,
    type: String,
    title: String
  }

  connect() {
    if (!this.hasDataValue || !this.hasTypeValue) return

    const context = this.element.getContext("2d")
    const showLegend = this.typeValue !== "bar"

    this.chart = new Chart(context, {
      type: this.typeValue,
      data: this.dataValue,
      options: {
        responsive: true,
        plugins: {
          legend: { display: showLegend, labels: { color: "#0f172a" } },
          title: this.hasTitleValue ? { display: true, text: this.titleValue, color: "#0f172a", font: { weight: "bold" } } : {},
          tooltip: {
            backgroundColor: "#0f172a",
            titleColor: "#e2e8f0",
            bodyColor: "#e2e8f0",
            borderColor: "#cbd5f5",
            borderWidth: 1
          }
        },
        scales: this.typeValue === "bar" ? { y: { beginAtZero: true, ticks: { stepSize: 1 } } } : {}
      }
    })
  }

  disconnect() {
    this.chart?.destroy()
  }
}

import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="recommendations"
export default class extends Controller {
  static targets = [
    "cardContainer",
    "statusText",
    "ignoredList",
    "ignoredCount",
    "watchlistList",
    "watchlistCount"
  ]

  static values = {
    movies: Array,
    watchlistsPath: String,
    csrfToken: String
  }

  connect() {
    this.queue = [...(this.moviesValue || [])]
    this.ignored = []
    this.watchlisted = []
    this.renderCard()
    this.updateCounts()
  }

  renderCard() {
    if (!this.cardContainerTarget) return

    this.cardContainerTarget.innerHTML = ""

    if (this.queue.length === 0) {
      this.cardContainerTarget.innerHTML = `
        <div class="card text-center space-y-2">
          <p class="text-xl font-semibold text-slate-900">You're all caught up!</p>
          <p class="text-slate-600">Come back later for more picks.</p>
        </div>
      `
      this.setStatus("No more recommendations in this session.")
      return
    }

    const movie = this.queue[0]
    const castList = movie.cast && movie.cast.length > 0 ? movie.cast.join(", ") : "N/A"
    const yearDisplay = movie.year || "N/A"
    const poster = movie.poster_url || "https://placehold.co/500x750?text=No+Image"

    this.cardContainerTarget.innerHTML = `
      <div class="overflow-hidden rounded-2xl border border-neutral-100 bg-white shadow-card ring-1 ring-inset ring-neutral-100">
        <div class="grid gap-6 lg:grid-cols-[1fr,1.1fr] items-stretch">
          <div class="relative bg-neutral-100">
            <img src="${poster}" alt="${this.escapeHtml(movie.title)}" class="h-full w-full object-cover">
            <div class="absolute inset-x-0 bottom-0 h-24 bg-gradient-to-t from-black/30 to-transparent"></div>
          </div>
          <div class="flex flex-col justify-between gap-6 p-6 lg:p-8">
            <div class="space-y-2">
              <div class="flex items-center gap-2 text-xs font-semibold uppercase tracking-wide text-brand-700">
                <span>Top pick</span>
                <span class="h-px w-10 bg-brand-200"></span>
                <span class="text-[11px] text-slate-500">${this.queue.length} in deck</span>
              </div>
              <h2 class="text-3xl lg:text-4xl font-display font-semibold text-slate-900">${this.escapeHtml(movie.title)}</h2>
              <p class="text-base text-slate-600">${yearDisplay}</p>
            </div>

            <div class="grid gap-3 sm:grid-cols-2">
              <div class="rounded-xl bg-neutral-50 p-4 ring-1 ring-neutral-100">
                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">Director</p>
                <p class="mt-1 text-lg font-semibold text-slate-900">${this.escapeHtml(movie.director || "Unknown")}</p>
              </div>
              <div class="rounded-xl bg-neutral-50 p-4 ring-1 ring-neutral-100">
                <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">Top Cast</p>
                <p class="mt-1 text-lg font-semibold text-slate-900">${this.escapeHtml(castList)}</p>
              </div>
            </div>

            <div class="flex flex-wrap gap-3">
              <button class="btn btn-secondary" data-action="click->recommendations#ignore">
                Ignore for now
              </button>
              <a href="${movie.details_path}" class="btn btn-primary">
                View details
              </a>
              <button class="btn bg-amber-500 text-white shadow-sm hover:bg-amber-600 focus-visible:outline-amber-500" data-action="click->recommendations#addToWatchlist">
                Add to watchlist
              </button>
            </div>
          </div>
        </div>
      </div>
    `

    this.setStatus("Higher scored picks rise to the top. Decide what to do with this movie.")
  }

  ignore(event) {
    event.preventDefault()
    if (this.queue.length === 0) return

    const movie = this.queue.shift()
    this.ignored.push(movie)
    this.appendListItem(this.ignoredListTarget, movie.title)
    this.updateCounts()
    this.renderCard()
    this.setStatus(`${movie.title} ignored for this session.`)
  }

  async addToWatchlist(event) {
    event.preventDefault()
    if (this.queue.length === 0) return

    const movie = this.queue[0]
    this.setStatus("Adding to your watchlist...")

    const payload = new URLSearchParams({
      tmdb_id: movie.tmdb_id,
      title: movie.title,
      poster_url: movie.poster_url
    })

    try {
      const response = await fetch(this.watchlistsPathValue, {
        method: "POST",
        headers: {
          "X-CSRF-Token": this.csrfTokenValue,
          "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
          "Accept": "text/html"
        },
        body: payload
      })

      if (!response.ok) throw new Error("Failed to add to watchlist")

      this.queue.shift()
      this.watchlisted.push(movie)
      this.appendListItem(this.watchlistListTarget, movie.title)
      this.updateCounts()
      this.renderCard()
      this.setStatus(`${movie.title} added to your watchlist.`)
    } catch (error) {
      this.setStatus("Could not add to watchlist. Please try again.")
    }
  }

  appendListItem(listTarget, title) {
    if (!listTarget) return

    const placeholder = listTarget.querySelector("li")
    if (placeholder && placeholder.dataset.placeholder === "true") {
      placeholder.remove()
    }

    const item = document.createElement("li")
    item.textContent = title
    item.className = "text-sm text-slate-700 bg-neutral-50 border border-neutral-200 rounded-lg px-3 py-2"
    listTarget.appendChild(item)
  }

  updateCounts() {
    if (this.ignoredCountTarget) {
      this.ignoredCountTarget.textContent = this.ignored.length
    }

    if (this.watchlistCountTarget) {
      this.watchlistCountTarget.textContent = this.watchlisted.length
    }
  }

  setStatus(message) {
    if (this.statusTextTarget) {
      this.statusTextTarget.textContent = message
    }
  }

  escapeHtml(value) {
    return (value || "").toString().replace(/[&<>"]/g, (char) => {
      switch (char) {
        case "&":
          return "&amp;"
        case "<":
          return "&lt;"
        case ">":
          return "&gt;"
        case '"':
          return "&quot;"
        default:
          return char
      }
    })
  }
}

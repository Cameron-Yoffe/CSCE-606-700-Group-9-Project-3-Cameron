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
        <div class="rounded-3xl border border-slate-800 bg-slate-900/70 p-8 text-center text-white shadow-2xl">
          <p class="text-2xl font-semibold">You're all caught up!</p>
          <p class="mt-2 text-slate-300">Come back later for more picks.</p>
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
      <div class="relative overflow-hidden rounded-3xl border border-slate-800 bg-slate-900/70 shadow-2xl">
        <div class="absolute inset-0 bg-gradient-to-br from-amber-500/10 via-transparent to-slate-900/70 pointer-events-none"></div>
        <div class="grid gap-6 lg:grid-cols-[1fr,1.2fr] items-stretch p-6 lg:p-10">
          <div class="rounded-2xl overflow-hidden bg-slate-800/70 border border-slate-700 shadow-lg">
            <img src="${poster}" alt="${this.escapeHtml(movie.title)}" class="w-full h-full object-cover">
          </div>
          <div class="flex flex-col justify-between space-y-6">
            <div class="space-y-2">
              <div class="flex items-center gap-3 text-amber-300 text-sm font-semibold uppercase tracking-[0.15em]">
                <span>Top pick</span>
                <span class="h-px w-10 bg-amber-400/60"></span>
                <span class="text-xs text-amber-200">${this.queue.length} in deck</span>
              </div>
              <h2 class="text-3xl lg:text-4xl font-black text-white">${this.escapeHtml(movie.title)}</h2>
              <p class="text-slate-300 text-lg">${yearDisplay}</p>
            </div>

            <div class="grid gap-4 sm:grid-cols-2">
              <div class="rounded-xl bg-slate-800/60 border border-slate-700 p-4">
                <p class="text-xs uppercase tracking-[0.15em] text-slate-400">Director</p>
                <p class="text-lg font-semibold text-white mt-1">${this.escapeHtml(movie.director || "Unknown")}</p>
              </div>
              <div class="rounded-xl bg-slate-800/60 border border-slate-700 p-4">
                <p class="text-xs uppercase tracking-[0.15em] text-slate-400">Top Cast</p>
                <p class="text-lg font-semibold text-white mt-1">${this.escapeHtml(castList)}</p>
              </div>
            </div>

            <div class="flex flex-wrap gap-3">
              <button class="inline-flex items-center gap-2 rounded-xl border border-slate-700 px-4 py-3 text-slate-200 hover:border-slate-500 hover:text-white transition"
                      data-action="click->recommendations#ignore">
                <span class="text-lg">✕</span>
                Ignore for now
              </button>
              <a href="${movie.details_path}" class="inline-flex items-center gap-2 rounded-xl bg-emerald-500 px-5 py-3 text-white font-semibold shadow-lg hover:bg-emerald-600 transition">
                <span class="text-lg">✓</span>
                View details
              </a>
              <button class="inline-flex items-center gap-2 rounded-xl bg-amber-500 px-5 py-3 text-white font-semibold shadow-lg hover:bg-amber-600 transition"
                      data-action="click->recommendations#addToWatchlist">
                <span class="text-lg">★</span>
                Add to watchlist
              </button>
            </div>
          </div>
        </div>
      </div>
    `

    this.setStatus("Higher scored picks stay on top. Decide what to do with this movie.")
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
    item.className = "text-sm text-slate-200 bg-slate-800/70 border border-slate-700 rounded-lg px-3 py-2"
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

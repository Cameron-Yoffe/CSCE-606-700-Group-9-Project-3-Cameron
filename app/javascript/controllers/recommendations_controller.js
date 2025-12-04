import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="recommendations"
export default class extends Controller {
  static targets = [
    "cardContainer",
    "statusText",
    "deckCount",
    "ignoredList",
    "ignoredCount",
    "watchlistList",
    "watchlistCount",
    "reloadButton",
    "allIgnoredList",
    "allIgnoredToggle",
    "allIgnoredSection"
  ]

  static values = {
    movies: Array,
    watchlistsPath: String,
    csrfToken: String,
    status: String,
    statusUrl: String,
    refreshUrl: String,
    runId: Number
  }

  connect() {
    this.storageKey = "movie-recommendations-state"
    this.allIgnoredStorageKey = "movie-recommendations-ignored-all"
    this.loading = this.statusValue !== "completed"
    this.signature = this.buildSignature()
    this.allIgnored = this.loadAllIgnored()

    if (this.loading) {
      this.resetState()
      this.saveState()
      this.renderLists()
      this.renderCard()
      this.updateCounts()
      this.startPolling()
    } else {
      this.restoreState()
      this.renderCard()
      this.renderLists()
      this.updateCounts()
    }
  }

  disconnect() {
    this.stopPolling()
  }

  buildSignature() {
    return JSON.stringify({
      runId: this.runIdValue,
      ids: (this.moviesValue || []).map((movie) => movie.tmdb_id)
    })
  }

  restoreState() {
    const storedState = this.loadState()

    if (storedState && storedState.signature === this.signature) {
      this.queue = this.applyExclusions(storedState.queue || [])
      this.ignored = storedState.ignored || []
      this.watchlisted = storedState.watchlisted || []
    } else {
      this.resetState()
      this.saveState()
    }
  }

  resetState() {
    this.queue = this.applyExclusions([...(this.moviesValue || [])])
    this.ignored = []
    this.watchlisted = []
  }

  applyExclusions(queue) {
    return queue.filter((movie) => !this.isIgnored(movie))
  }

  loadState() {
    try {
      const stored = localStorage.getItem(this.storageKey)
      return stored ? JSON.parse(stored) : null
    } catch (error) {
      console.warn("Could not load recommendations state", error)
      return null
    }
  }

  loadAllIgnored() {
    try {
      const stored = localStorage.getItem(this.allIgnoredStorageKey)
      return stored ? JSON.parse(stored) : []
    } catch (error) {
      console.warn("Could not load ignored movies", error)
      return []
    }
  }

  saveState() {
    try {
      localStorage.setItem(
        this.storageKey,
        JSON.stringify({
          signature: this.signature,
          queue: this.queue,
          ignored: this.ignored,
          watchlisted: this.watchlisted
        })
      )
    } catch (error) {
      console.warn("Could not save recommendations state", error)
    }
  }

  saveAllIgnored() {
    try {
      localStorage.setItem(this.allIgnoredStorageKey, JSON.stringify(this.allIgnored))
    } catch (error) {
      console.warn("Could not save ignored movies", error)
    }
  }

  addToAllIgnored(movie) {
    if (this.isIgnored(movie)) return

    this.allIgnored.unshift(movie)
    this.saveAllIgnored()
  }

  removeFromAllIgnored(movie) {
    const index = this.allIgnored.findIndex((item) => String(item.tmdb_id) === String(movie.tmdb_id))
    if (index === -1) return

    this.allIgnored.splice(index, 1)
    this.saveAllIgnored()
  }

  isWatchlisted(movie) {
    return this.watchlisted.some((item) => String(item.tmdb_id) === String(movie.tmdb_id))
  }

  findMovieByTmdbId(tmdbId) {
    return (this.moviesValue || []).find((movie) => String(movie.tmdb_id) === String(tmdbId))
  }

  isIgnored(movie) {
    return this.allIgnored.some((item) => String(item.tmdb_id) === String(movie.tmdb_id))
  }

  renderCard() {
    if (!this.cardContainerTarget) return

    this.cardContainerTarget.innerHTML = ""

    if (this.loading) {
      this.cardContainerTarget.innerHTML = `
        <div class="card text-center space-y-3">
          <div class="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-brand-50 text-brand-600">
            <svg class="h-6 w-6 animate-spin" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 3v3m0 12v3m9-9h-3M6 12H3m15.364 6.364l-2.121-2.121M8.757 8.757 6.636 6.636m12.728 0-2.121 2.121M8.757 15.243l-2.121 2.121" />
            </svg>
          </div>
          <p class="text-xl font-semibold text-slate-900">Finding suggestions</p>
          <p class="text-slate-600">Hang tight while we search TMDB and your library.</p>
        </div>
      `
      this.setStatus("Finding suggestions for you...")
      this.updateCounts()
      return
    }

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
      <div class="overflow-hidden rounded-xl border border-neutral-100 bg-white shadow-card ring-1 ring-inset ring-neutral-100">
        <div class="flex flex-col gap-4 lg:flex-row lg:items-stretch">
          <div class="flex items-center justify-center bg-neutral-100 p-4 lg:w-[240px]">
            <img src="${poster}" alt="${this.escapeHtml(movie.title)}" class="h-full max-h-[420px] w-full object-contain">
          </div>
          <div class="flex flex-1 flex-col justify-between gap-4 p-5 lg:p-7">
            <div class="space-y-2">
              <div class="flex items-center gap-2 text-[11px] font-semibold uppercase tracking-wide text-brand-700">
                <span>Top pick</span>
                <span class="h-px w-10 bg-brand-200"></span>
                <span class="text-[10px] text-slate-500">${this.queue.length} in deck</span>
              </div>
              <h2 class="text-2xl lg:text-3xl font-display font-semibold text-slate-900">${this.escapeHtml(movie.title)}</h2>
              <p class="text-sm text-slate-600">${yearDisplay}</p>
            </div>

            <div class="grid gap-3 sm:grid-cols-2">
              <div class="rounded-xl bg-neutral-50 p-4 ring-1 ring-neutral-100">
                <p class="text-[11px] font-semibold uppercase tracking-wide text-slate-500">Director</p>
                <p class="mt-1 text-base font-semibold text-slate-900">${this.escapeHtml(movie.director || "Unknown")}</p>
              </div>
              <div class="rounded-xl bg-neutral-50 p-4 ring-1 ring-neutral-100">
                <p class="text-[11px] font-semibold uppercase tracking-wide text-slate-500">Top Cast</p>
                <p class="mt-1 text-base font-semibold text-slate-900">${this.escapeHtml(castList)}</p>
              </div>
            </div>

            <div class="flex flex-wrap gap-2">
              <button class="btn btn-secondary text-sm py-2" data-action="click->recommendations#ignore">
                Ignore for now
              </button>
              <a href="${movie.details_path}" class="btn btn-primary text-sm py-2">
                View details
              </a>
              <button class="btn text-sm py-2 bg-amber-500 text-white shadow-sm hover:bg-amber-600 focus-visible:outline-amber-500" data-action="click->recommendations#addToWatchlist">
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
    this.addToAllIgnored(movie)
    this.renderIgnoredList()
    this.renderAllIgnoredList()
    this.updateCounts()
    this.renderCard()
    this.setStatus(`${movie.title} ignored for this session.`)
    this.saveState()
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
      this.renderWatchlistList()
      this.updateCounts()
      this.renderCard()
      this.setStatus(`${movie.title} added to your watchlist.`)
      this.saveState()
    } catch (error) {
      this.setStatus("Could not add to watchlist. Please try again.")
    }
  }

  renderLists() {
    this.renderIgnoredList()
    this.renderWatchlistList()
    this.renderAllIgnoredList()
  }

  renderIgnoredList() {
    if (!this.ignoredListTarget) return

    this.ignoredListTarget.innerHTML = ""

    if (this.ignored.length === 0) {
      this.ignoredListTarget.innerHTML = '<li class="text-sm text-slate-600" data-placeholder="true">Nothing ignored yet.</li>'
      return
    }

    this.ignored.forEach((movie) => {
      const item = document.createElement("li")
      item.className =
        "group flex items-center justify-between gap-3 text-sm text-slate-700 bg-neutral-50 border border-neutral-200 rounded-lg px-3 py-2"

      const title = document.createElement("span")
      title.textContent = movie.title

      const removeButton = document.createElement("button")
      removeButton.type = "button"
      removeButton.dataset.tmdbId = movie.tmdb_id
      removeButton.dataset.action = "click->recommendations#removeIgnored"
      removeButton.className =
        "opacity-0 group-hover:opacity-100 transition-opacity text-slate-400 hover:text-slate-700 focus:opacity-100"
      removeButton.setAttribute("aria-label", `Remove ${movie.title} from ignored`)
      removeButton.innerHTML = "&times;"

      item.appendChild(title)
      item.appendChild(removeButton)

      this.ignoredListTarget.appendChild(item)
    })
  }

  renderWatchlistList() {
    if (!this.watchlistListTarget) return

    this.watchlistListTarget.innerHTML = ""

    if (this.watchlisted.length === 0) {
      this.watchlistListTarget.innerHTML = '<li class="text-sm text-slate-600" data-placeholder="true">No new watchlist picks yet.</li>'
      return
    }

    this.watchlisted.forEach((movie) => {
      const item = document.createElement("li")
      item.textContent = movie.title
      item.className = "text-sm text-slate-700 bg-neutral-50 border border-neutral-200 rounded-lg px-3 py-2"
      this.watchlistListTarget.appendChild(item)
    })
  }

  renderAllIgnoredList() {
    if (!this.hasAllIgnoredListTarget) return

    this.allIgnoredListTarget.innerHTML = ""

    if (this.allIgnored.length === 0) {
      this.allIgnoredListTarget.innerHTML = '<li class="text-sm text-slate-600" data-placeholder="true">No ignored titles yet.</li>'
      return
    }

    this.allIgnored.forEach((movie) => {
      const item = document.createElement("li")
      item.className =
        "group flex items-center justify-between gap-3 text-sm text-slate-700 bg-neutral-50 border border-neutral-200 rounded-lg px-3 py-2"

      const title = document.createElement("span")
      title.textContent = movie.title

      const removeButton = document.createElement("button")
      removeButton.type = "button"
      removeButton.dataset.tmdbId = movie.tmdb_id
      removeButton.dataset.action = "click->recommendations#removeFromAllIgnoredList"
      removeButton.className =
        "opacity-0 group-hover:opacity-100 transition-opacity text-slate-400 hover:text-slate-700 focus:opacity-100"
      removeButton.setAttribute("aria-label", `Return ${movie.title} to recommendations`)
      removeButton.innerHTML = "&times;"

      item.appendChild(title)
      item.appendChild(removeButton)
      this.allIgnoredListTarget.appendChild(item)
    })
  }

  toggleAllIgnored(event) {
    event.preventDefault()
    if (!this.hasAllIgnoredSectionTarget || !this.hasAllIgnoredToggleTarget) return

    const isHidden = this.allIgnoredSectionTarget.classList.toggle("hidden") === true
    this.allIgnoredToggleTarget.textContent = isHidden ? "View all ignored" : "Hide all ignored"
  }

  removeFromAllIgnoredList(event) {
    event.preventDefault()
    const button = event.currentTarget
    const tmdbId = button?.dataset?.tmdbId

    const index = this.allIgnored.findIndex((movie) => String(movie.tmdb_id) === String(tmdbId))
    if (index === -1) return

    const [movie] = this.allIgnored.splice(index, 1)

    const sessionIndex = this.ignored.findIndex((item) => String(item.tmdb_id) === String(tmdbId))
    if (sessionIndex !== -1) {
      this.ignored.splice(sessionIndex, 1)
    }

    if (!this.queue.some((item) => String(item.tmdb_id) === String(tmdbId)) && !this.isWatchlisted(movie)) {
      const candidate = this.findMovieByTmdbId(tmdbId) || movie
      this.queue.push(candidate)
    }

    this.saveAllIgnored()
    this.saveState()
    this.renderLists()
    this.renderCard()
    this.updateCounts()
    this.setStatus(`${movie.title} returned to your deck.`)
  }

  clearAllIgnored(event) {
    event.preventDefault()
    if (this.allIgnored.length === 0) return

    const existingIds = new Set(this.queue.map((movie) => String(movie.tmdb_id)))

    this.allIgnored = []
    this.ignored = []
    this.saveAllIgnored()

    ;(this.moviesValue || []).forEach((movie) => {
      if (!existingIds.has(String(movie.tmdb_id)) && !this.isWatchlisted(movie)) {
        this.queue.push(movie)
      }
    })

    this.saveState()
    this.renderLists()
    this.renderCard()
    this.updateCounts()
    this.setStatus("Ignored titles cleared and returned to your deck.")
  }

  removeIgnored(event) {
    event.preventDefault()
    const button = event.currentTarget
    const tmdbId = button?.dataset?.tmdbId

    const index = this.ignored.findIndex((movie) => String(movie.tmdb_id) === String(tmdbId))
    if (index === -1) return

    const [movie] = this.ignored.splice(index, 1)
    this.removeFromAllIgnored(movie)

    if (!this.queue.some((queued) => queued.tmdb_id === movie.tmdb_id)) {
      this.queue.push(movie)
    }

    this.renderCard()
    this.renderIgnoredList()
    this.renderAllIgnoredList()
    this.updateCounts()
    this.setStatus(`${movie.title} returned to your deck.`)
    this.saveState()
  }

  async reload(event) {
    event.preventDefault()
    if (!this.refreshUrlValue) return

    this.loading = true
    this.moviesValue = []
    this.resetState()
    this.saveState()
    this.renderLists()
    this.renderCard()
    this.updateCounts()
    this.disableReloadButton(true)

    try {
      const response = await fetch(this.refreshUrlValue, {
        method: "POST",
        headers: {
          "X-CSRF-Token": this.csrfTokenValue,
          "Accept": "application/json"
        }
      })

      if (!response.ok) throw new Error("Failed to start a new search")

      const data = await response.json()
      this.runIdValue = data.run_id
      this.statusValue = data.status
      this.signature = this.buildSignature()
      this.updateStatusUrl(data.run_id)
      this.startPolling()
      this.setStatus("Finding suggestions for you...")
    } catch (error) {
      this.loading = false
      this.renderCard()
      this.disableReloadButton(false)
      this.setStatus("Could not start a new search right now.")
    }
  }

  startPolling() {
    this.stopPolling()
    if (!this.statusUrlValue) return

    this.pollTimer = setTimeout(() => this.pollStatus(), 1500)
  }

  stopPolling() {
    if (this.pollTimer) {
      clearTimeout(this.pollTimer)
      this.pollTimer = null
    }
  }

  async pollStatus() {
    try {
      const response = await fetch(this.statusUrlValue, { headers: { Accept: "application/json" } })
      if (!response.ok) throw new Error("Status check failed")

      const data = await response.json()
      this.runIdValue = data.run_id
      this.statusValue = data.status

      if (data.status === "completed") {
        this.loading = false
        this.moviesValue = data.recommendations || []
        this.signature = this.buildSignature()
        this.resetState()
        this.saveState()
        this.renderLists()
        this.renderCard()
        this.updateCounts()
        this.setStatus("Tap a button to start curating your picks.")
        this.disableReloadButton(false)
        this.stopPolling()
        return
      }

      if (data.status === "failed") {
        this.loading = false
        this.renderCard()
        this.disableReloadButton(false)
        this.setStatus("We couldn't fetch suggestions. Try reloading.")
        this.stopPolling()
        return
      }

      this.loading = true
      this.renderCard()
      this.disableReloadButton(true)
      this.startPolling()
    } catch (error) {
      this.loading = false
      this.renderCard()
      this.disableReloadButton(false)
      this.setStatus("We couldn't check for suggestions. Reload to try again.")
    }
  }

  updateStatusUrl(runId) {
    if (!this.statusUrlValue) return

    const [base] = this.statusUrlValue.split("?")
    this.statusUrlValue = `${base}?run_id=${runId}`
  }

  disableReloadButton(disabled) {
    if (this.hasReloadButtonTarget) {
      this.reloadButtonTarget.disabled = disabled
      this.reloadButtonTarget.classList.toggle("opacity-60", disabled)
      this.reloadButtonTarget.classList.toggle("cursor-not-allowed", disabled)
    }
  }

  updateCounts() {
    if (this.deckCountTarget) {
      this.deckCountTarget.textContent = this.loading ? "Searching..." : `${this.queue.length} in deck`
    }

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

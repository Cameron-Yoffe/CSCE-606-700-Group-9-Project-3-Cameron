import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = []
  static values = { 
    position: Number,
    csrfToken: String
  }

  connect() {
    this.csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    this.createModal()
  }

  disconnect() {
    // Clean up modal when controller is disconnected
    if (this.modal) {
      this.modal.remove()
    }
  }

  openMovieSelector(event) {
    const position = event.currentTarget.dataset.position
    this.positionValue = parseInt(position)
    this.showModal()
  }

  showModal() {
    // Ensure modal exists before showing
    if (!this.modal) {
      console.error("Modal not found")
      return
    }
    
    this.updateModalPosition()
    this.modal.classList.remove("hidden")
    document.body.style.overflow = "hidden"
  }

  closeModal() {
    if (this.modal) {
      this.modal.classList.add("hidden")
      document.body.style.overflow = "auto"
      this.clearSearch()
    }
  }

  handleBackdropClick(event) {
    // Only close if clicking the backdrop, not the modal content
    if (event.target === event.currentTarget) {
      this.closeModal()
    }
  }

  updateModalPosition() {
    // Update the modal header with the current position
    const header = this.modal.querySelector('h3')
    if (header) {
      header.textContent = `Select Movie for Position ${this.positionValue}`
    }
  }

  createModal() {
    const modal = document.createElement("div")
    this.modal = modal
    modal.className = "fixed inset-0 z-[9999] flex items-center justify-center bg-black/50 p-4 hidden"
    modal.addEventListener('click', (e) => {
      if (e.target === modal) this.closeModal()
    })
    modal.innerHTML = `
      <div class="bg-white rounded-xl shadow-2xl max-w-2xl w-full max-h-[80vh] overflow-hidden flex flex-col" data-modal-content>
        <!-- Modal Header -->
        <div class="border-b border-neutral-200 p-6">
          <div class="flex items-center justify-between">
            <h3 class="text-2xl font-semibold text-slate-900">Select Movie for Position #</h3>
            <button 
              class="text-neutral-400 hover:text-neutral-600 transition-colors">
              <svg class="h-6 w-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
              </svg>
            </button>
          </div>
        </div>

        <!-- Modal Body -->
        <div class="flex-1 overflow-y-auto p-6">
          <div class="space-y-6">
            <!-- Search Section -->
            <div>
              <label class="block text-sm font-medium text-slate-700 mb-2">Search for a movie</label>
              <input 
                type="text"
                placeholder="Search for a movie..."
                class="w-full rounded-lg border border-neutral-300 px-4 py-2 focus:border-brand-500 focus:outline-none focus:ring-2 focus:ring-brand-500/20"
              />
            </div>

            <!-- Search Results -->
            <div class="space-y-2 min-h-[200px]" data-search-results>
              <p class="text-center text-neutral-500 py-8">Search for a movie to add to your top 5</p>
            </div>
          </div>
        </div>
      </div>
    `
    
    // Add event listeners after creating modal
    const closeBtn = modal.querySelector('button')
    closeBtn.addEventListener('click', () => this.closeModal())
    
    const searchInput = modal.querySelector('input[type="text"]')
    searchInput.addEventListener('input', (e) => this.searchMovies(e))
    
    // Store references to these elements
    this.searchResultsContainer = modal.querySelector('[data-search-results]')
    
    // Append to body for proper z-index
    document.body.appendChild(modal)
  }

  searchMovies(event) {
    const query = event.target.value.trim()
    
    if (query.length < 2) {
      this.searchResultsContainer.innerHTML = '<p class="text-center text-neutral-500 py-8">Type at least 2 characters to search</p>'
      return
    }

    this.searchResultsContainer.innerHTML = '<p class="text-center text-neutral-500 py-8">Searching...</p>'

    // Debounce search
    clearTimeout(this.searchTimeout)
    this.searchTimeout = setTimeout(() => {
      this.performSearch(query)
    }, 300)
  }

  async performSearch(query) {
    try {
      const response = await fetch(`/movies?search=${encodeURIComponent(query)}`, {
        headers: {
          'Accept': 'application/json'
        }
      })

      if (!response.ok) throw new Error('Search failed')

      const data = await response.json()
      this.displaySearchResults(data.movies || [])
    } catch (error) {
      console.error('Search error:', error)
      this.searchResultsContainer.innerHTML = '<p class="text-center text-red-500 py-8">Search failed. Please try again.</p>'
    }
  }

  displaySearchResults(movies) {
    if (movies.length === 0) {
      this.searchResultsContainer.innerHTML = '<p class="text-center text-neutral-500 py-8">No movies found</p>'
      return
    }

    this.searchResultsContainer.innerHTML = `
      <div class="space-y-2 max-h-96 overflow-y-auto">
        ${movies.slice(0, 10).map(movie => `
          <button
            data-tmdb-id="${movie.tmdb_id || movie.id}"
            data-title="${this.escapeHtml(movie.title)}"
            data-poster-url="${movie.poster_url || ''}"
            class="w-full flex items-center gap-3 p-3 rounded-lg bg-white hover:bg-neutral-50 border border-neutral-200 hover:border-brand-400 transition-all text-left group">
            <div class="flex-shrink-0 w-16 h-24 rounded overflow-hidden bg-neutral-100">
              ${movie.poster_url ? 
                `<img src="${movie.poster_url}" alt="${this.escapeHtml(movie.title)}" class="w-full h-full object-cover" />` : 
                `<div class="w-full h-full flex items-center justify-center bg-neutral-200">
                  <svg class="w-8 h-8 text-neutral-400" fill="currentColor" viewBox="0 0 20 20">
                    <path d="M4 3a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V5a2 2 0 00-2-2H4zm12 12H4l4-8 3 6 2-4 3 6z"/>
                  </svg>
                </div>`
              }
            </div>
            <div class="flex-1 min-w-0">
              <h4 class="font-semibold text-slate-900 truncate group-hover:text-brand-600">${this.escapeHtml(movie.title)}</h4>
              ${movie.release_date ? `<p class="text-sm text-slate-600 mt-0.5">${new Date(movie.release_date).getFullYear()}</p>` : ''}
            </div>
            <svg class="w-5 h-5 text-neutral-400 group-hover:text-brand-500 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
            </svg>
          </button>
        `).join('')}
      </div>
    `
    
    // Add click handlers to search results
    this.searchResultsContainer.querySelectorAll('button').forEach(btn => {
      btn.addEventListener('click', (e) => this.selectSearchMovie(e))
    })
  }
  
  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  async selectSearchMovie(event) {
    const tmdbId = event.currentTarget.dataset.tmdbId
    const title = event.currentTarget.dataset.title
    const posterUrl = event.currentTarget.dataset.posterUrl
    
    // First, add to favorites (which will create the movie if needed)
    try {
      const response = await fetch('/favorites', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfToken,
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          tmdb_id: tmdbId,
          title: title,
          poster_url: posterUrl
        })
      })

      if (response.redirected) {
        window.location.href = response.url
        return
      }

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}))
        throw new Error(errorData.error || 'Failed to add to favorites')
      }

      const data = await response.json()
      
      // Now set the top position with the newly created or existing favorite
      if (data.favorite && data.favorite.id) {
        await this.setTopPosition(data.favorite.id)
      } else {
        // Fallback: reload the page
        window.location.reload()
      }
    } catch (error) {
      console.error('Error adding to favorites:', error)
      alert('Failed to add movie. Please try again.')
    }
  }

  async setTopPosition(favoriteId) {
    try {
      const response = await fetch(`/favorites/${favoriteId}/set_top_position`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfToken
        },
        body: JSON.stringify({
          position: this.positionValue
        })
      })

      if (!response.ok) throw new Error('Failed to set position')

      // Reload the page to show the updated top movies
      window.location.reload()
    } catch (error) {
      console.error('Error setting top position:', error)
      alert('Failed to add movie to top 5. Please try again.')
    }
  }

  async removeFromTop(event) {
    event.stopPropagation()
    const favoriteId = event.currentTarget.dataset.favoriteId

    if (!confirm('Remove this movie from your top 5?')) return

    try {
      const response = await fetch(`/favorites/${favoriteId}/remove_top_position`, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfToken
        }
      })

      if (!response.ok) throw new Error('Failed to remove')

      window.location.reload()
    } catch (error) {
      console.error('Error removing from top:', error)
      alert('Failed to remove movie. Please try again.')
    }
  }

  clearSearch() {
    const searchInput = this.modal.querySelector('input[type="text"]')
    if (searchInput) {
      searchInput.value = ''
    }
    if (this.searchResultsContainer) {
      this.searchResultsContainer.innerHTML = '<p class="text-center text-neutral-500 py-8">Search for a movie to add to your top 5</p>'
    }
  }
}

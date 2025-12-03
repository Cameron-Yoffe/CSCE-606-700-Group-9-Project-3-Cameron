import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["badge", "refreshIcon"]
  
  connect() {
    this.storageKey = "activity_feed_read_items"
    this.lastVisitKey = "activity_feed_last_visit"
    
    // Get read items from localStorage
    this.readItems = this.getReadItems()
    
    // Get last visit timestamp
    const lastVisit = localStorage.getItem(this.lastVisitKey)
    this.lastVisitTimestamp = lastVisit ? parseInt(lastVisit) : 0
    
    // Show notification dots for new/unread items
    this.updateNotificationDots()
    
    // Update last visit time
    localStorage.setItem(this.lastVisitKey, Date.now().toString())
  }
  
  getReadItems() {
    const stored = localStorage.getItem(this.storageKey)
    return stored ? JSON.parse(stored) : []
  }
  
  saveReadItems() {
    localStorage.setItem(this.storageKey, JSON.stringify(this.readItems))
  }
  
  updateNotificationDots() {
    const cards = this.element.querySelectorAll('.activity-card')
    let unreadCount = 0
    
    cards.forEach(card => {
      const activityId = card.dataset.activityId
      const activityTimestamp = parseInt(card.dataset.activityTimestamp)
      const dot = card.querySelector('.activity-dot')
      
      // Show dot if:
      // 1. Activity is not in read items AND
      // 2. Activity is newer than last visit (or it's the first visit)
      const isUnread = !this.readItems.includes(activityId)
      const isNew = activityTimestamp > this.lastVisitTimestamp
      
      if (dot && isUnread && isNew) {
        dot.classList.remove('hidden')
        unreadCount++
      } else if (dot) {
        dot.classList.add('hidden')
      }
    })
    
    // Update badge count
    this.updateBadge(unreadCount)
  }
  
  updateBadge(count) {
    if (this.hasBadgeTarget) {
      if (count > 0) {
        this.badgeTarget.textContent = count > 99 ? '99+' : count
        this.badgeTarget.style.display = 'inline-flex'
      } else {
        this.badgeTarget.textContent = ''
        this.badgeTarget.style.display = 'none'
      }
    }
  }
  
  markAsRead(event) {
    const card = event.currentTarget
    const activityId = card.dataset.activityId
    const dot = card.querySelector('.activity-dot')
    
    // Don't mark as read if clicking a link inside the card
    if (event.target.tagName === 'A') {
      return
    }
    
    // Add to read items if not already there
    if (!this.readItems.includes(activityId)) {
      this.readItems.push(activityId)
      this.saveReadItems()
    }
    
    // Hide the dot
    if (dot) {
      dot.classList.add('hidden')
    }
    
    // Update badge count
    const visibleDots = this.element.querySelectorAll('.activity-dot:not(.hidden)')
    this.updateBadge(visibleDots.length)
  }
  
  refresh(event) {
    event.preventDefault()
    
    const button = event.currentTarget
    const icon = this.hasRefreshIconTarget ? this.refreshIconTarget : button.querySelector('svg')
    
    // Disable button during refresh
    button.disabled = true
    button.classList.add('opacity-50', 'cursor-not-allowed')
    
    // Use Turbo to refresh just the activity feed section
    // We'll use a fetch request and Turbo's visit
    fetch(window.location.href, {
      headers: {
        'Accept': 'text/html',
        'Turbo-Frame': '_top'
      }
    })
    .then(response => response.text())
    .then(html => {
      // Parse the response HTML
      const parser = new DOMParser()
      const doc = parser.parseFromString(html, 'text/html')
      
      // Find the activity feed section in the response
      const newFeed = doc.querySelector('[data-controller="activity-feed"]')
      
      if (newFeed) {
        // Replace the current activity feed with the new one
        this.element.innerHTML = newFeed.innerHTML
        
        // Re-run the notification dots update
        this.updateNotificationDots()
      }
      
      // Re-enable button
      button.disabled = false
      button.classList.remove('opacity-50', 'cursor-not-allowed')
    })
    .catch(error => {
      console.error('Failed to refresh activity feed:', error)
      
      // Re-enable on error
      button.disabled = false
      button.classList.remove('opacity-50', 'cursor-not-allowed')
    })
  }
  
  clearAll(event) {
    event.preventDefault()
    
    const cards = this.element.querySelectorAll('.activity-card')
    
    cards.forEach(card => {
      const activityId = card.dataset.activityId
      const dot = card.querySelector('.activity-dot')
      
      // Add to read items
      if (!this.readItems.includes(activityId)) {
        this.readItems.push(activityId)
      }
      
      // Hide dot
      if (dot) {
        dot.classList.add('hidden')
      }
    })
    
    // Save all read items
    this.saveReadItems()
    
    // Update badge to 0
    this.updateBadge(0)
    
    // Show a brief confirmation
    const clearButton = event.currentTarget
    if (clearButton) {
      const originalHTML = clearButton.innerHTML
      clearButton.innerHTML = `
        <svg class="w-4 h-4 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
        </svg>
        Done!
      `
      clearButton.classList.add('text-green-600')
      clearButton.classList.remove('text-slate-500')
      
      setTimeout(() => {
        clearButton.innerHTML = originalHTML
        clearButton.classList.remove('text-green-600')
        clearButton.classList.add('text-slate-500')
      }, 2000)
    }
  }
}

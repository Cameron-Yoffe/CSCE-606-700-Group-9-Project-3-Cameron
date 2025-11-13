import { Controller } from "@hotwired/stimulus"
import { staggerFadeIn, floatIn, cleanupTimeline } from "lib/gsap_helpers"

export default class extends Controller {
  static targets = ["card", "title"]
  static values = {
    once: { type: Boolean, default: true }
  }

  connect() {
    this.titleAnimations = this.titleTargets.map((target, idx) =>
      floatIn(target, { blur: false, delay: idx * 0.05 })
    )

    this.cardsTimeline = this.cardTargets.length
      ? staggerFadeIn(this.cardTargets, { once: this.onceValue, trigger: this.element })
      : null
  }

  disconnect() {
    this.titleAnimations?.forEach((animation) => cleanupTimeline(animation))
    cleanupTimeline(this.cardsTimeline)
  }
}

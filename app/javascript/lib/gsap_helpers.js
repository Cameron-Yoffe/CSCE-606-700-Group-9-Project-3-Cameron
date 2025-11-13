import gsap from "gsap"
import ScrollTrigger from "gsap/ScrollTrigger"

let registered = false

export function initGsap() {
  if (!registered) {
    gsap.registerPlugin(ScrollTrigger)
    registered = true
  }

  return { gsap, ScrollTrigger }
}

export function prefersReducedMotion() {
  return window.matchMedia("(prefers-reduced-motion: reduce)").matches
}

export function staggerFadeIn(elements, options = {}) {
  const { gsap } = initGsap()
  const config = {
    y: 40,
    duration: 0.9,
    ease: "power3.out",
    stagger: 0.15,
    trigger: null,
    start: "top 80%",
    once: true,
    blur: true,
    scroll: true,
    ...options
  }

  if (!elements || elements.length === 0 || prefersReducedMotion()) {
    return null
  }

  const fromState = { y: config.y, autoAlpha: 0 }
  if (config.blur) fromState.filter = "blur(14px)"

  const timeline = gsap.fromTo(
    elements,
    fromState,
    {
      y: 0,
      autoAlpha: 1,
      filter: "blur(0px)",
      duration: config.duration,
      ease: config.ease,
      stagger: config.stagger
    }
  )

  if (config.scroll) {
    const trigger = config.trigger || elements[0].closest("[data-animation-trigger]") || elements[0]

    ScrollTrigger.create({
      animation: timeline,
      trigger,
      start: config.start,
      toggleActions: config.once ? "play none none none" : "play none none reset"
    })
  }

  return timeline
}

export function floatIn(element, options = {}) {
  const { gsap } = initGsap()
  const config = {
    duration: 1,
    delay: 0,
    y: 20,
    blur: true,
    ease: "power2.out",
    ...options
  }

  if (!element || prefersReducedMotion()) return null

  return gsap.fromTo(
    element,
    {
      y: config.y,
      autoAlpha: 0,
      filter: config.blur ? "blur(10px)" : "blur(0px)"
    },
    {
      y: 0,
      autoAlpha: 1,
      filter: "blur(0px)",
      duration: config.duration,
      delay: config.delay,
      ease: config.ease
    }
  )
}

export function cleanupTimeline(timeline) {
  if (timeline && typeof timeline.kill === "function") {
    timeline.kill()
  }
}

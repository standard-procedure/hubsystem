import { Controller } from "@hotwired/stimulus"

// Scrolls a container to a position on connect.
// Usage: data-controller="scroll-anchor" data-scroll-anchor-position-value="last"
// Values: "last" (scroll to bottom), "first" (scroll to top), "selected" (scroll to [data-scroll-anchor-target="selected"])
export default class extends Controller {
  static values = { position: { type: String, default: "last" } }

  connect() {
    if (this.positionValue === "last") {
      this.element.scrollTop = this.element.scrollHeight
    } else if (this.positionValue === "selected") {
      const target = this.element.querySelector('[data-scroll-anchor-target="selected"]')
      if (target) {
        const isFirst = target === this.element.querySelector('.grid-body').firstElementChild
        target.scrollIntoView({ block: isFirst ? "start" : "center" })
      }
    }
  }
}

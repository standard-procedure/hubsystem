import { Controller } from "@hotwired/stimulus"

// Scrolls a container to the bottom on connect.
// Usage: data-controller="scroll-anchor" data-scroll-anchor-position-value="last"
export default class extends Controller {
  static values = { position: { type: String, default: "last" } }

  connect() {
    if (this.positionValue === "last") {
      this.element.scrollTop = this.element.scrollHeight
    }
  }
}

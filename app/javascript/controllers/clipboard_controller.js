import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  async copy(event) {
    const text = event?.params?.text || "";
    try {
      await navigator.clipboard.writeText(text)
    } catch (error) {
      console.error("Clipboard failed:", error)
    }
  }
}
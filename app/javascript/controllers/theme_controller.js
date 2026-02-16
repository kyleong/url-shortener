import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle"]

  connect() {
    const savedTheme = localStorage.getItem('theme') || 'light'
    this.applyTheme(savedTheme)

    if (savedTheme === 'dark') {
      this.toggleTarget.checked = true
    }
  }

  toggleTheme() {
    const newTheme = this.toggleTarget.checked ? 'dark' : 'light'
    this.applyTheme(newTheme)
    localStorage.setItem('theme', newTheme)
  }

  applyTheme(theme) {
    const html = document.documentElement;
    html.setAttribute("data-theme", theme);
  }
}

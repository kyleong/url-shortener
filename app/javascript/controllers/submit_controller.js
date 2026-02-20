import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input"];

  normalize() {
    const value = this.inputTarget.value.trim();
    if (value && !value.match(/^https?:\/\//i)) {
      this.inputTarget.value = "https://" + value;
    }
  }
}

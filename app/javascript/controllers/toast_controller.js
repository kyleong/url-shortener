import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { message: String }

  connect() {
    if (this.hasMessageValue) {
      this.show() 
    }
  }

  show(event) {
    const message = event?.params?.message || this.messageValue || "";

    const toastContainer = document.getElementById("toast-container");

    const alert = document.createElement("div");
    alert.classList.add("alert", "alert-sm", "shadow-xl");

    alert.innerHTML = message;
    toastContainer.appendChild(alert);

    setTimeout(() => {
      alert.classList.add(
        "opacity-0",
        "translate-x-4",
        "duration-300",
        "transition-all",
      );
      setTimeout(() => {
        alert.remove();
      }, 300);
    }, 3000);
  }
}

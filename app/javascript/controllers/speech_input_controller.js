import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "button", "status"]

  connect() {
    this.recognition = null
    this.listening = false
    this.supported = !!(window.SpeechRecognition || window.webkitSpeechRecognition)

    if (!this.supported && this.hasButtonTarget) {
      this.buttonTarget.disabled = true
      this.buttonTarget.classList.add("opacity-40", "cursor-not-allowed")
      this.buttonTarget.setAttribute("title", "Voice input not supported in this browser")
    }
  }

  toggle() {
    if (!this.supported) return
    if (this.listening) {
      this.stop()
    } else {
      this.start()
    }
  }

  start() {
    if (!this.supported || this.listening) return

    const Recognition = window.SpeechRecognition || window.webkitSpeechRecognition
    this.recognition = new Recognition()
    this.recognition.lang = document.documentElement.lang || "en-US"
    this.recognition.interimResults = false
    this.recognition.maxAlternatives = 1

    this.recognition.onresult = (event) => {
      const transcript = event.results?.[0]?.[0]?.transcript
      if (!transcript || !this.hasInputTarget) return

      const current = this.inputTarget.value || ""
      const spacer = current.length > 0 && !current.endsWith(" ") ? " " : ""
      this.inputTarget.value = `${current}${spacer}${transcript}`
      this.inputTarget.dispatchEvent(new Event("input", { bubbles: true }))
      this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
      this.dispatch("result", { bubbles: true, detail: { transcript, input: this.inputTarget } })
    }

    this.recognition.onend = () => {
      this.listening = false
      this.updateUi()
    }

    this.recognition.onerror = () => {
      this.listening = false
      this.updateUi()
    }

    this.listening = true
    this.updateUi()
    this.recognition.start()
  }

  stop() {
    if (!this.recognition) return
    this.recognition.stop()
    this.listening = false
    this.updateUi()
  }

  updateUi() {
    if (this.hasButtonTarget) {
      this.buttonTarget.textContent = this.listening ? "Listening" : "Voice"
      this.buttonTarget.classList.toggle("bg-emerald-500/10", this.listening)
      this.buttonTarget.classList.toggle("border-emerald-400/60", this.listening)
    }
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = this.listening ? "Listening..." : ""
    }
  }
}

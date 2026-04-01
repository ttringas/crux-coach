import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "status"]
  static values = { url: String, key: String }

  connect() {
    this._lastSaved = this.inputTarget.value
  }

  async save() {
    const value = this.inputTarget.value.trim()
    if (value === this._lastSaved) return

    this._lastSaved = value
    this.showStatus("saving")

    try {
      const token = document.querySelector("meta[name='csrf-token']")?.content
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": token,
          "Accept": "application/json"
        },
        body: JSON.stringify({
          benchmark_key: this.keyValue,
          benchmark: { value: value, tested_at: new Date().toISOString().split("T")[0] }
        })
      })

      if (response.ok) {
        this.showStatus("saved")
      } else {
        this.showStatus("error")
      }
    } catch (e) {
      this.showStatus("error")
    }
  }

  showStatus(state) {
    if (!this.hasStatusTarget) return

    if (state === "saving") {
      this.statusTarget.innerHTML = '<span class="text-slate-500">saving...</span>'
    } else if (state === "saved") {
      this.statusTarget.innerHTML = '<span class="text-emerald-400">✓ saved</span>'
      setTimeout(() => {
        if (this.hasStatusTarget) {
          const today = new Date()
          this.statusTarget.innerHTML = `<span class="text-slate-600">${today.getMonth()+1}/${today.getDate()}/${String(today.getFullYear()).slice(2)}</span>`
        }
      }, 2000)
    } else if (state === "error") {
      this.statusTarget.innerHTML = '<span class="text-red-400">error</span>'
      setTimeout(() => {
        if (this.hasStatusTarget) {
          this.statusTarget.innerHTML = ""
        }
      }, 3000)
    }
  }
}

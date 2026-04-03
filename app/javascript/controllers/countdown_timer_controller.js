import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "minutes",
    "seconds",
    "display",
    "startButton",
    "stopButton",
    "resetButton",
    "inputWrapper",
    "displayWrapper",
    "container"
  ]

  connect() {
    this.intervalId = null
    this.remaining = null
    this.hasStarted = false
    this.flashTimeoutId = null
    this.originalMinutes = this.hasMinutesTarget ? this.minutesTarget.value : "0"
    this.originalSeconds = this.hasSecondsTarget ? this.secondsTarget.value : "0"
    this.updateDisplay(this.totalSeconds())
    this.showInputs()
    this.showButtons()
  }

  disconnect() {
    this.stop()
    this.clearFlash()
  }

  start() {
    if (this.intervalId) return
    if (this.remaining === null) {
      const total = this.totalSeconds()
      if (total <= 0) return
      this.remaining = total
    }

    this.hasStarted = true
    this.updateDisplay(this.remaining)
    this.intervalId = setInterval(() => this.tick(), 1000)
    this.showDisplay()
    this.showButtons()
  }

  stop() {
    if (this.intervalId) {
      clearInterval(this.intervalId)
      this.intervalId = null
    }
    this.showDisplay()
    this.showButtons()
  }

  reset() {
    this.stop()
    this.remaining = null
    this.hasStarted = false
    if (this.hasMinutesTarget) this.minutesTarget.value = this.originalMinutes
    if (this.hasSecondsTarget) this.secondsTarget.value = this.originalSeconds
    this.updateDisplay(this.totalSeconds())
    this.showInputs()
    this.showButtons()
    this.clearFlash()
  }

  tick() {
    this.remaining -= 1
    this.updateDisplay(this.remaining)

    if (this.remaining <= 0) {
      this.remaining = 0
      this.updateDisplay(this.remaining)
      this.stop()
      this.triggerCompletionEffects()
    }
  }

  totalSeconds() {
    const minutes = parseInt(this.minutesTarget?.value || "0", 10)
    const seconds = parseInt(this.secondsTarget?.value || "0", 10)
    const safeMinutes = Number.isNaN(minutes) ? 0 : Math.max(0, minutes)
    const safeSeconds = Number.isNaN(seconds) ? 0 : Math.max(0, seconds)
    return safeMinutes * 60 + safeSeconds
  }

  updateDisplay(seconds) {
    if (!this.hasDisplayTarget) return
    const safeSeconds = Math.max(0, seconds || 0)
    const minutes = Math.floor(safeSeconds / 60)
    const remaining = safeSeconds % 60
    this.displayTarget.textContent = `${minutes}:${String(remaining).padStart(2, "0")}`
  }

  showInputs() {
    if (this.hasInputWrapperTarget) this.inputWrapperTarget.style.display = ""
    if (this.hasDisplayWrapperTarget) this.displayWrapperTarget.style.display = "none"
  }

  showDisplay() {
    if (this.hasInputWrapperTarget) this.inputWrapperTarget.style.display = "none"
    if (this.hasDisplayWrapperTarget) this.displayWrapperTarget.style.display = ""
  }

  showButtons() {
    const running = Boolean(this.intervalId)
    if (this.hasStartButtonTarget) {
      this.startButtonTarget.style.display = running ? "none" : "inline-flex"
    }
    if (this.hasStopButtonTarget) {
      this.stopButtonTarget.style.display = running ? "inline-flex" : "none"
    }
    if (this.hasResetButtonTarget) {
      this.resetButtonTarget.style.display = this.hasStarted ? "inline-flex" : "none"
    }
  }

  triggerCompletionEffects() {
    this.startFlash()
    this.playCompletionSound()
  }

  startFlash() {
    if (!this.hasContainerTarget) return
    this.containerTarget.classList.add("border-emerald-400", "ring-2", "ring-emerald-400/60", "animate-pulse")
    if (this.flashTimeoutId) clearTimeout(this.flashTimeoutId)
    this.flashTimeoutId = setTimeout(() => this.clearFlash(), 15000)
  }

  clearFlash() {
    if (!this.hasContainerTarget) return
    if (this.flashTimeoutId) {
      clearTimeout(this.flashTimeoutId)
      this.flashTimeoutId = null
    }
    this.containerTarget.classList.remove("border-emerald-400", "ring-2", "ring-emerald-400/60", "animate-pulse")
  }

  playCompletionSound() {
    const AudioContext = window.AudioContext || window.webkitAudioContext
    if (!AudioContext) return

    const context = new AudioContext()
    const now = context.currentTime

    const gain = context.createGain()
    gain.gain.setValueAtTime(0.0001, now)
    gain.gain.exponentialRampToValueAtTime(0.2, now + 0.05)
    gain.gain.exponentialRampToValueAtTime(0.0001, now + 1.6)

    const osc1 = context.createOscillator()
    osc1.type = "sine"
    osc1.frequency.setValueAtTime(440, now)
    osc1.frequency.exponentialRampToValueAtTime(660, now + 0.4)

    const osc2 = context.createOscillator()
    osc2.type = "sine"
    osc2.frequency.setValueAtTime(880, now + 0.4)

    osc1.connect(gain)
    osc2.connect(gain)
    gain.connect(context.destination)

    osc1.start(now)
    osc1.stop(now + 0.6)
    osc2.start(now + 0.4)
    osc2.stop(now + 1.2)

    setTimeout(() => context.close(), 1800)
  }
}

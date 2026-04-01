import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "body"]

  open(data) {
    const exercises = data.exercises || []
    const exerciseRows = exercises.length > 0
      ? exercises.map(ex => `
          <tr class="border-t border-slate-700/50">
            <td class="py-2 pr-3 text-sm text-slate-100 font-medium">${ex.name || ''}</td>
            <td class="py-2 px-3 text-sm text-slate-400 text-center">${ex.sets || '-'}</td>
            <td class="py-2 px-3 text-sm text-slate-400 text-center">${ex.reps || ex.duration || '-'}</td>
            <td class="py-2 px-3 text-sm text-slate-400 text-center">${ex.rest || ex.rest_seconds ? (ex.rest || ex.rest_seconds + 's') : '-'}</td>
            <td class="py-2 pl-3 text-sm text-slate-500">${ex.notes || ex.description || ''}</td>
          </tr>`).join('')
      : `<tr><td colspan="5" class="py-4 text-center text-sm text-slate-500">No exercises listed</td></tr>`

    this.bodyTarget.innerHTML = `
      <div class="space-y-4">
        <button type="button" class="absolute top-4 right-4 text-slate-400 hover:text-slate-100 transition" data-action="click->session-modal#close" aria-label="Close">
          <svg width="20" height="20" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/></svg>
        </button>
        <div>
          <div class="text-xs text-slate-400 uppercase tracking-wide">${data.type} · ${data.intensity}</div>
          <h3 class="text-lg font-semibold mt-1">${data.title}</h3>
        </div>
        <div class="flex items-center gap-4 text-sm text-slate-400">
          <span>${data.duration || '-'} min</span>
          <span class="capitalize">${data.status}</span>
        </div>
        ${data.description ? `<p class="text-sm text-slate-300">${data.description}</p>` : ''}
        <div class="mt-2">
          <h4 class="text-sm font-semibold text-slate-200 mb-2">Exercises</h4>
          <div class="overflow-x-auto">
            <table class="w-full text-left">
              <thead>
                <tr class="text-xs text-slate-500 uppercase tracking-wide">
                  <th class="pb-2 pr-3">Exercise</th>
                  <th class="pb-2 px-3 text-center">Sets</th>
                  <th class="pb-2 px-3 text-center">Reps</th>
                  <th class="pb-2 px-3 text-center">Rest</th>
                  <th class="pb-2 pl-3">Notes</th>
                </tr>
              </thead>
              <tbody>${exerciseRows}</tbody>
            </table>
          </div>
        </div>
        ${data.url ? `<div class="pt-2">
          <a href="${data.url}" class="inline-flex items-center gap-2 bg-amber-500 text-slate-950 px-4 py-2 rounded-md text-sm font-semibold hover:bg-amber-400 transition">
            Go To Session →
          </a>
        </div>` : ''}
      </div>
    `
    this.overlayTarget.classList.remove("hidden")
  }

  openFromPill(event) {
    event.preventDefault()
    const el = event.currentTarget
    let exercises = []
    try { exercises = JSON.parse(el.dataset.exercises || '[]') } catch(e) {}
    this.open({
      title: el.dataset.title || '',
      type: el.dataset.sessionType || '',
      intensity: el.dataset.intensity || '',
      duration: el.dataset.duration || '',
      status: el.dataset.status || '',
      description: el.dataset.description || '',
      url: el.dataset.sessionUrl || '',
      exercises: exercises
    })
  }

  close() {
    this.overlayTarget.classList.add("hidden")
  }

  closeOnBackdrop(event) {
    if (!this.bodyTarget.contains(event.target)) {
      this.close()
    }
  }

  connect() {
    this.boundKeydown = (e) => { if (e.key === "Escape") this.close() }
    document.addEventListener("keydown", this.boundKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydown)
  }
}

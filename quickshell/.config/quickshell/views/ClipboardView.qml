import QtQuick
import "../components"
import "../services"
import "../core"

LauncherPanel {
    title: "Clipboard"
    placeholder: "Search clipboard history…"
    actionLabel: "Copy"
    clipboard: true
    results: ClipboardService.search(query)
    busy: ClipboardService.busy
    loading: ClipboardService.loading
    error: ClipboardService.errorSession === LauncherController.session ? ClipboardService.error : ""
    emptyText: query.trim() ? "No clipboard entries match your search" : "Your clipboard history is empty"
    onActivate: id => ClipboardService.copy(id, LauncherController.session)
}

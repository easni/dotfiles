import QtQuick
import "../components"
import "../services"
import "../core"

LauncherPanel {
    title: "Applications"
    placeholder: "Search applications…"
    actionLabel: "Launch"
    results: AppLauncherService.search(query)
    busy: AppLauncherService.busy
    error: AppLauncherService.errorSession === LauncherController.session ? AppLauncherService.error : ""
    emptyText: query.trim() ? "No applications match your search" : "No applications found"
    onActivate: id => AppLauncherService.launch(id, LauncherController.session)
}

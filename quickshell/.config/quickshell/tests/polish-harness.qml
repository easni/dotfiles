import QtQuick
import QtTest
import Quickshell
import "../components"
import "../services"
import "../views"

ShellRoot {
    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 600
        implicitHeight: 600
        color: "#252a33"
        Item {
            id: canvas
            anchors.fill: parent
            property real externalValue: 0.25
            ControlSlider {
                id: slider
                width: 300
                height: 35
                value: canvas.externalValue
                onValueChangedByUser: function(value) { canvas.externalValue = value }
            }
            Loader {
                id: panel
                anchors.centerIn: parent
                width: item ? item.implicitWidth : 0
                height: item ? item.implicitHeight : 0
            }
        }
    }
    Component { id: controls; ControlCenterView { availableWidth: 300; availableHeight: 350 } }
    Component { id: themes; ThemeSelectorView { availableWidth: 300; availableHeight: 350 } }
    Component { id: wallpapers; WallpaperSelectorView { availableWidth: 300; availableHeight: 350 } }
    TestCase {
        id: checks
        when: false
        function check(value, message) { if (!value) throw new Error(message) }
        function until(predicate, message) {
            for (let i = 0; i < 100 && !predicate(); ++i) wait(50)
            check(predicate(), message)
        }
        function grab(name) {
            let done = false
            canvas.grabToImage(result => {
                done = result.saveToFile(Quickshell.env("LUCI_TEST_OUTPUT") + "/" + name + ".png")
            })
            until(() => done, "Screenshot failed")
        }
        function run() {
            // Corrupt saved theme must recover without running the sync script.
            until(() => ThemeService.ready, "Theme never became ready")
            check(ThemeService.currentTheme === "monochrome", "Missing fallback theme")
            mouseClick(slider, 240, 17)
            check(canvas.externalValue > 0.7, "Slider click failed")
            canvas.externalValue = 0.15
            wait(30)
            check(slider.value === 0.15 && slider.displayValue === 0.15, "Slider binding was lost")
            slider.forceActiveFocus()
            keyClick(Qt.Key_Right)
            check(Math.abs(canvas.externalValue - 0.2) < 0.001, "Slider keyboard adjustment failed")
            slider.visible = false

            AudioService.setVolume(25)
            AudioService.setVolume(60)
            AudioService.setVolume(83)
            BrightnessService.setBrightness(25)
            BrightnessService.setBrightness(60)
            BrightnessService.setBrightness(79)
            wait(600)
            AudioService.volume = 0
            BrightnessService.brightness = 0
            AudioService.update()
            BrightnessService.update()
            until(() => AudioService.volume === 83 && BrightnessService.brightness === 79, "Final slider command was lost")

            until(() => WifiService.available && !WifiService.busy, "Wi-Fi unavailable")
            check(WifiService.enabled && !WifiService.connected, "Expected disconnected radio on")
            WifiService.connected = true
            WifiService.ssid = "Previously connected"
            WifiService.toggle()
            for (let i = 0; i < 6; ++i) {
                wait(100)
                check(WifiService.connecting && !WifiService.displayEnabled
                    && WifiService.subtitle === "Turning off…", "Off transition flashed stale state")
            }
            until(() => !WifiService.busy && !WifiService.enabled, "Disconnected radio did not turn off")
            WifiService.toggle()
            for (let i = 0; i < 6; ++i) {
                wait(100)
                check(WifiService.connecting && WifiService.displayEnabled
                    && WifiService.subtitle === "Turning on…", "On transition flashed stale state")
            }
            until(() => !WifiService.busy && WifiService.enabled, "Radio did not turn on")
            check(!WifiService.connecting && WifiService.subtitle === "Not connected", "Wi-Fi stuck connecting")
            WifiService.toggle()
            until(() => !WifiService.busy && WifiService.error !== "", "Failed Wi-Fi command did not finish")
            check(WifiService.displayEnabled && WifiService.enabled, "Failed toggle did not restore highlight")
            console.log("PASS delayed Wi-Fi transitions and failed-toggle rollback")

            for (const entry of [[controls, "controls-narrow"], [themes, "themes-narrow"], [wallpapers, "wallpapers-narrow"]]) {
                panel.sourceComponent = entry[0]
                wait(250)
                check(panel.width <= 300 && panel.height <= 350, "Panel exceeds available size")
                grab(entry[1])
            }
            panel.sourceComponent = themes
            wait(100)
            // Selecting with a pointer must preserve subsequent keyboard selection.
            const grid = panel.item.children[0].children[1]
            mouseClick(grid, 120, 150)
            const selected = panel.item.selectedIndex
            panel.item.forceActiveFocus()
            keyClick(Qt.Key_Down)
            check(panel.item.selectedIndex === selected + 1 && grid.currentIndex === selected + 1,
                  "Theme mouse/keyboard selection diverged")
            wait(300)
            console.log("PASS slider bindings, queued settings, theme fallback, Wi-Fi toggle, narrow panels and theme navigation")
            Qt.quit()
        }
    }
    Timer {
        interval: 200
        running: true
        onTriggered: {
            try { checks.run() }
            catch (error) { console.error("FAIL", error.stack); Qt.quit() }
        }
    }
}

import AppKit
import SpeedCore
import SwiftUI

@MainActor
final class SettingsWindowController {
    static let shared = SettingsWindowController()

    private var window: NSWindow?

    private init() {}

    func show(appController: SpeedAppController) {
        let hostingController = NSHostingController(
            rootView: SettingsWindowView(appController: appController)
        )

        if let window {
            window.contentViewController = hostingController
            window.title = appController.localization.strings.settingsTitle
            bringToFront(window)
            return
        }

        let window = NSWindow(contentViewController: hostingController)
        window.title = appController.localization.strings.settingsTitle
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .visible
        window.toolbarStyle = .preference
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 720, height: 780))
        window.center()

        self.window = window
        bringToFront(window)
    }

    private func bringToFront(_ window: NSWindow) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }
}

import AppKit
import SpeedCore
import SwiftUI

@main
struct SpeedMenuBarApp: App {
    @State
    private var appController = SpeedAppController()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            SpeedMenuPanel(
                viewModel: appController.speedTestViewModel,
                onOpenSettings: {
                    SettingsWindowController.shared.show(appController: appController)
                }
            )
                .frame(width: 356)
        } label: {
            MenuBarStatusIcon(
                symbolName: appController.speedTestViewModel.menuBarSymbol,
                isRunning: appController.speedTestViewModel.isRunning
            )
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarStatusIcon: View {
    let symbolName: String
    let isRunning: Bool

    var body: some View {
        Image(systemName: symbolName)
            .symbolVariant(.fill)
            .font(.system(size: 14, weight: .semibold))
            .contentTransition(.symbolEffect(.replace))
            .help(isRunning ? "Speedtest läuft" : "Speed öffnen")
    }
}

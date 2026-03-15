import AppKit
import SpeedCore
import SwiftUI

@main
struct SpeedMenuBarApp: App {
    @State
    private var appController: SpeedAppController

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
        _appController = State(
            initialValue: SpeedAppController(
                applicationTerminator: {
                    Task { @MainActor in
                        NSApplication.shared.terminate(nil)
                    }
                }
            )
        )
    }

    var body: some Scene {
        MenuBarExtra {
            SpeedMenuPanel(
                viewModel: appController.speedTestViewModel,
                localization: appController.localization,
                onOpenSettings: {
                    SettingsWindowController.shared.show(appController: appController)
                }
            )
            .frame(width: SpeedChrome.panelWidth)
            .environment(\.locale, appController.localization.locale)
        } label: {
            MenuBarStatusIcon(
                symbolName: appController.speedTestViewModel.menuBarSymbol,
                isRunning: appController.speedTestViewModel.isRunning,
                localization: appController.localization
            )
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarStatusIcon: View {
    let symbolName: String
    let isRunning: Bool
    let localization: SpeedLocalization

    var body: some View {
        Image(systemName: symbolName)
            .symbolVariant(.fill)
            .font(.system(size: 14, weight: .semibold))
            .contentTransition(.symbolEffect(.replace))
            .help(isRunning ? localization.strings.menuBarRunningHelp : localization.strings.menuBarOpenHelp)
    }
}

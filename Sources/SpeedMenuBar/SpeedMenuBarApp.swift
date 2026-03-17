import AppKit
import Observation
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
                nextAutomaticTestAt: appController.nextAutomaticTestAt,
                onOpenSettings: {
                    SettingsWindowController.shared.show(appController: appController)
                }
            )
            .frame(width: SpeedChrome.panelWidth)
            .environment(\.locale, appController.localization.locale)
        } label: {
            MenuBarStatusItem(
                viewModel: appController.speedTestViewModel,
                displayMode: appController.menuBarDisplayMode,
                localization: appController.localization
            )
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarStatusItem: View {
    @Bindable var viewModel: SpeedTestViewModel
    let displayMode: MenuBarDisplayMode
    let localization: SpeedLocalization

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: viewModel.menuBarSymbol)
                .symbolVariant(.fill)
                .font(.system(size: 14, weight: .semibold))
                .contentTransition(.symbolEffect(.replace))

            if let menuBarText = viewModel.menuBarText(for: displayMode) {
                Text(menuBarText)
                    .font(.system(size: 11.5, weight: .semibold))
                    .monospacedDigit()
                    .lineLimit(1)
            }
        }
        .help(
            viewModel.isRunning
                ? localization.strings.menuBarRunningHelp
                : localization.strings.menuBarOpenHelp
        )
    }
}

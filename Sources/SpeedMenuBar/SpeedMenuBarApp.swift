import AppKit
import SpeedCore
import SwiftUI

@main
struct SpeedMenuBarApp: App {
    @State
    private var viewModel = SpeedTestViewModel()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            SpeedMenuPanel(viewModel: viewModel)
                .frame(width: 372)
        } label: {
            MenuBarStatusIcon(
                symbolName: viewModel.menuBarSymbol,
                isRunning: viewModel.isRunning
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

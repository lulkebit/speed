import AppKit
import SpeedCore
import SwiftUI

struct SettingsWindowView: View {
    @Bindable var appController: SpeedAppController

    var body: some View {
        let strings = appController.localization.strings

        VStack(alignment: .leading, spacing: 18) {
            header

            Form {
                Section {
                    Toggle(
                        strings.launchAtLoginToggleTitle,
                        isOn: Binding(
                            get: { appController.launchAtLoginState.isEnabledForToggle },
                            set: { appController.setLaunchAtLoginEnabled($0) }
                        )
                    )
                    .disabled(!appController.canConfigureLaunchAtLogin)

                    if let launchAtLoginDescription = appController.launchAtLoginDescription {
                        Text(launchAtLoginDescription)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }

                    if let launchAtLoginMessage = appController.launchAtLoginMessage {
                        Text(launchAtLoginMessage)
                            .font(.system(size: 12))
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text(strings.settingsSectionLaunchAtLogin)
                }

                Section {
                    Picker(
                        strings.automaticTestIntervalLabel,
                        selection: $appController.automaticTestInterval
                    ) {
                        ForEach(AutoTestInterval.allCases) { interval in
                            Text(interval.title(using: strings))
                                .tag(interval)
                        }
                    }
                    .pickerStyle(.menu)

                    Text(appController.nextAutomaticTestDescription)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    Text(appController.automaticTestingFootnote)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    Toggle(
                        strings.automaticTestOnNetworkChangeTitle,
                        isOn: $appController.automaticallyTestsOnNetworkChange
                    )

                    Text(strings.automaticTestOnNetworkChangeDescription)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                } header: {
                    Text(strings.settingsSectionAutomaticTests)
                }

                Section {
                    Picker(
                        strings.menuBarDisplayModeLabel,
                        selection: $appController.menuBarDisplayMode
                    ) {
                        ForEach(MenuBarDisplayMode.allCases) { displayMode in
                            Text(displayMode.title(using: strings))
                                .tag(displayMode)
                        }
                    }
                    .pickerStyle(.menu)

                    HStack(spacing: 12) {
                        Text(strings.menuBarPreviewLabel)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)

                        Spacer(minLength: 12)

                        menuBarPreview
                    }
                } header: {
                    Text(strings.settingsSectionMenuBar)
                }

                Section {
                    HistorySectionView(
                        viewModel: appController.speedTestViewModel,
                        localization: appController.localization
                    )
                } header: {
                    Text(strings.settingsSectionHistory)
                }

                Section {
                    Toggle(
                        strings.updateAutomaticChecksToggleTitle,
                        isOn: $appController.automaticallyChecksForUpdates
                    )

                    updateStatusCard

                    HStack(spacing: 12) {
                        Button(appController.updateCheckButtonTitle) {
                            appController.checkForUpdates()
                        }
                        .buttonStyle(.bordered)
                        .disabled(!appController.canCheckForUpdates)

                        if appController.shouldShowInstallUpdateButton {
                            Button(appController.updateInstallButtonTitle) {
                                appController.installAvailableUpdate()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!appController.canInstallUpdate)
                        }

                        if let availableUpdateReleaseURL = appController.availableUpdateReleaseURL {
                            Link(strings.updateReleaseNotesTitle, destination: availableUpdateReleaseURL)
                                .font(.system(size: 12))
                        }
                    }
                } header: {
                    Text(strings.settingsSectionUpdates)
                }

                Section {
                    Picker(
                        strings.languagePickerLabel,
                        selection: $appController.appLanguage
                    ) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(
                                strings.appLanguageOptionTitle(
                                    language,
                                    resolvedSystemLanguage: appController.localization.systemLanguage
                                )
                            )
                            .tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text(strings.settingsSectionLanguage)
                }
            }
            .formStyle(.grouped)

            Spacer()
        }
        .padding(24)
        .frame(minWidth: 680, minHeight: 760)
        .background(WindowTitleUpdater(title: strings.settingsTitle))
        .environment(\.locale, appController.localization.locale)
    }

    private var header: some View {
        let strings = appController.localization.strings

        return HStack(alignment: .center, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                SpeedChrome.brand.opacity(0.22),
                                SpeedChrome.brand.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(SpeedChrome.brand.opacity(0.12), lineWidth: 1)
                    )

                Image(systemName: "speedometer")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(SpeedChrome.brand)
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text(strings.appName)
                    .font(.system(size: 28, weight: .semibold))

                Text(strings.settingsTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                Text(appController.installedVersionDescription)
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 16)

            VStack(alignment: .trailing, spacing: 8) {
                scheduleBadge

                Text(appController.nextAutomaticTestDescription)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 220, alignment: .trailing)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.45), lineWidth: 1)
        )
    }

    private var updateStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(updateToneColor.opacity(0.14))
                        .frame(width: 34, height: 34)

                    if appController.showsUpdateProgressIndicator {
                        ProgressView()
                            .controlSize(.small)
                            .tint(updateToneColor)
                    } else {
                        Image(systemName: appController.updateStatusSymbolName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(updateToneColor)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(appController.updateStatusTitle)
                        .font(.system(size: 13, weight: .semibold))

                    Text(appController.updateStatusDescription)
                        .font(.system(size: 12))
                        .foregroundStyle(appController.updateStatusUsesErrorStyle ? .red : .secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            Divider()

            HStack(spacing: 12) {
                Label(appController.installedVersionDescription, systemImage: "shippingbox")
                    .lineLimit(1)

                Spacer(minLength: 0)

                Label(appController.updateLastCheckedDescription, systemImage: "clock")
                    .lineLimit(1)
            }
            .font(.system(size: 11.5, weight: .medium))
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.45), lineWidth: 1)
        )
    }

    private var scheduleBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: appController.automaticTestInterval == .off ? "pause.circle.fill" : "clock.fill")
                .foregroundStyle(
                    appController.automaticTestInterval == .off ? Color.secondary : SpeedChrome.brand
                )

            Text(appController.automaticTestInterval.shortTitle(using: appController.localization.strings))
                .foregroundStyle(.secondary)
        }
        .font(.system(size: 11.5, weight: .semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.45), lineWidth: 1)
        )
    }

    private var updateToneColor: Color {
        switch appController.updateStatusTone {
        case .neutral:
            SpeedChrome.brand
        case .muted:
            .secondary
        case .informative:
            .blue
        case .success:
            .green
        case .accent:
            .orange
        case .error:
            .red
        }
    }

    private var menuBarPreview: some View {
        HStack(spacing: 6) {
            Image(systemName: appController.speedTestViewModel.menuBarSymbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            if let menuBarText = appController.speedTestViewModel.menuBarText(
                for: appController.menuBarDisplayMode
            ) {
                Text(menuBarText)
                    .font(.system(size: 11.5, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.45), lineWidth: 1)
        )
    }

}

private struct WindowTitleUpdater: NSViewRepresentable {
    let title: String

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            view.window?.title = title
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            nsView.window?.title = title
        }
    }
}

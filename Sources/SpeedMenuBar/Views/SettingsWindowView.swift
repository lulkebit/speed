import AppKit
import SpeedCore
import SwiftUI

struct SettingsWindowView: View {
    @Bindable var appController: SpeedAppController

    var body: some View {
        let strings = appController.localization.strings

        VStack(alignment: .leading, spacing: 20) {
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
                } header: {
                    Text(strings.settingsSectionAutomaticTests)
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
        .frame(minWidth: 520, minHeight: 420)
        .background(WindowTitleUpdater(title: strings.settingsTitle))
        .environment(\.locale, appController.localization.locale)
    }

    private var header: some View {
        Text(appController.localization.strings.settingsTitle)
            .font(.system(size: 24, weight: .semibold))
    }

    private var updateStatusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(updateToneColor.opacity(0.14))
                        .frame(width: 30, height: 30)

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
                Text(appController.installedVersionDescription)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                Text(appController.updateLastCheckedDescription)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(updateCardBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(updateToneColor.opacity(0.18), lineWidth: 1)
        )
    }

    private var updateToneColor: Color {
        switch appController.updateStatusTone {
        case .neutral:
            .accentColor
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

    private var updateCardBackgroundColor: Color {
        switch appController.updateStatusTone {
        case .neutral:
            return .accentColor.opacity(0.08)
        case .muted:
            return .secondary.opacity(0.08)
        case .informative:
            return .blue.opacity(0.08)
        case .success:
            return .green.opacity(0.08)
        case .accent:
            return .orange.opacity(0.08)
        case .error:
            return .red.opacity(0.08)
        }
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

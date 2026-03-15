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
        .frame(minWidth: 460, minHeight: 280)
        .background(WindowTitleUpdater(title: strings.settingsTitle))
        .environment(\.locale, appController.localization.locale)
    }

    private var header: some View {
        Text(appController.localization.strings.settingsTitle)
            .font(.system(size: 24, weight: .semibold))
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

import SpeedCore
import SwiftUI

struct SettingsWindowView: View {
    @Bindable var appController: SpeedAppController

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header

            Form {
                Section("Autostart") {
                    Toggle(
                        "Speed bei der Anmeldung starten",
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
                }

                Section("Automatische Messungen") {
                    Picker(
                        "Intervall",
                        selection: $appController.automaticTestInterval
                    ) {
                        ForEach(AutoTestInterval.allCases) { interval in
                            Text(interval.title)
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
                }
            }
            .formStyle(.grouped)

            Spacer()
        }
        .padding(24)
        .frame(minWidth: 460, minHeight: 280)
    }

    private var header: some View {
        Text("Einstellungen")
            .font(.system(size: 24, weight: .semibold))
    }
}

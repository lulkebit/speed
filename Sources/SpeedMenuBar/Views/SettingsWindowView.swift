import AppKit
import SpeedCore
import SwiftUI

struct SettingsWindowView: View {
    @Bindable var appController: SpeedAppController

    var body: some View {
        let strings = appController.localization.strings

        ZStack {
            PanelBackground()
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                header

                SubtleDivider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        SettingsSection(title: strings.settingsSectionLaunchAtLogin) {
                            SettingsRow(
                                title: strings.launchAtLoginToggleTitle,
                                detail: appController.launchAtLoginDescription
                            ) {
                                Toggle(
                                    strings.launchAtLoginToggleTitle,
                                    isOn: Binding(
                                        get: { appController.launchAtLoginState.isEnabledForToggle },
                                        set: { appController.setLaunchAtLoginEnabled($0) }
                                    )
                                )
                                .labelsHidden()
                                .toggleStyle(.switch)
                                .controlSize(.small)
                                .disabled(!appController.canConfigureLaunchAtLogin)
                            }

                            if let launchAtLoginMessage = appController.launchAtLoginMessage {
                                sectionMessage(launchAtLoginMessage, color: .red)
                            }
                        }

                        sectionDivider

                        SettingsSection(title: strings.settingsSectionAutomaticTests) {
                            SettingsRow(
                                title: strings.automaticTestIntervalLabel,
                                detail: appController.nextAutomaticTestDescription
                            ) {
                                Picker(
                                    strings.automaticTestIntervalLabel,
                                    selection: $appController.automaticTestInterval
                                ) {
                                    ForEach(AutoTestInterval.allCases) { interval in
                                        Text(interval.title(using: strings))
                                            .tag(interval)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(width: 220, alignment: .trailing)
                            }

                            SettingsRow(
                                title: strings.automaticTestOnNetworkChangeTitle,
                                detail: strings.automaticTestOnNetworkChangeDescription
                            ) {
                                Toggle(
                                    strings.automaticTestOnNetworkChangeTitle,
                                    isOn: $appController.automaticallyTestsOnNetworkChange
                                )
                                .labelsHidden()
                                .toggleStyle(.switch)
                                .controlSize(.small)
                            }
                        }

                        sectionDivider

                        SettingsSection(title: strings.settingsSectionMenuBar) {
                            SettingsRow(
                                title: strings.menuBarDisplayModeLabel,
                                detail: nil
                            ) {
                                Picker(
                                    strings.menuBarDisplayModeLabel,
                                    selection: $appController.menuBarDisplayMode
                                ) {
                                    ForEach(MenuBarDisplayMode.allCases) { displayMode in
                                        Text(displayMode.title(using: strings))
                                            .tag(displayMode)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(width: 220, alignment: .trailing)
                            }

                            SettingsRow(
                                title: strings.menuBarPreviewLabel,
                                detail: nil
                            ) {
                                menuBarPreview
                            }
                        }

                        sectionDivider

                        SettingsSection(title: strings.settingsSectionHistory) {
                            HistorySectionView(
                                viewModel: appController.speedTestViewModel,
                                localization: appController.localization
                            )
                        }

                        sectionDivider

                        SettingsSection(title: strings.settingsSectionUpdates) {
                            SettingsRow(
                                title: strings.updateAutomaticChecksToggleTitle,
                                detail: nil
                            ) {
                                Toggle(
                                    strings.updateAutomaticChecksToggleTitle,
                                    isOn: $appController.automaticallyChecksForUpdates
                                )
                                .labelsHidden()
                                .toggleStyle(.switch)
                                .controlSize(.small)
                            }

                            SettingsRow(
                                title: appController.updateStatusTitle,
                                detail: appController.updateStatusDescription
                            ) {
                                VStack(alignment: .trailing, spacing: 4) {
                                    Label(appController.updateLastCheckedDescription, systemImage: "clock")
                                        .lineLimit(1)

                                    Label(appController.installedVersionDescription, systemImage: "shippingbox")
                                        .lineLimit(1)
                                }
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundStyle(appController.updateStatusUsesErrorStyle ? .red : SpeedChrome.textTertiary)
                            }

                            HStack(spacing: 10) {
                                Button {
                                    appController.checkForUpdates()
                                } label: {
                                    SettingsActionLabel(
                                        title: appController.updateCheckButtonTitle,
                                        tint: updateToneColor
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(!appController.canCheckForUpdates)
                                .opacity(appController.canCheckForUpdates ? 1 : 0.5)
                                .subtleHover(
                                    cornerRadius: 10,
                                    fill: updateToneColor.opacity(0.14),
                                    stroke: updateToneColor.opacity(0.22)
                                )

                                if appController.shouldShowInstallUpdateButton {
                                    Button {
                                        appController.installAvailableUpdate()
                                    } label: {
                                        SettingsActionLabel(
                                            title: appController.updateInstallButtonTitle,
                                            tint: .orange
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(!appController.canInstallUpdate)
                                    .opacity(appController.canInstallUpdate ? 1 : 0.5)
                                    .subtleHover(
                                        cornerRadius: 10,
                                        fill: Color.orange.opacity(0.14),
                                        stroke: Color.orange.opacity(0.22)
                                    )
                                }

                                if let availableUpdateReleaseURL = appController.availableUpdateReleaseURL {
                                    Link(destination: availableUpdateReleaseURL) {
                                        SettingsActionLabel(
                                            title: strings.updateReleaseNotesTitle,
                                            tint: SpeedChrome.textSecondary
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .subtleHover(cornerRadius: 10)
                                }
                            }
                            .padding(.top, 4)
                        }

                        sectionDivider

                        SettingsSection(title: strings.settingsSectionLanguage) {
                            SettingsRow(
                                title: strings.languagePickerLabel,
                                detail: nil
                            ) {
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
                                .labelsHidden()
                                .pickerStyle(.menu)
                                .frame(width: 220, alignment: .trailing)
                            }
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 22)
                    .padding(.bottom, 32)
                }
            }
        }
        .frame(minWidth: 760, minHeight: 720)
        .background(WindowTitleUpdater(title: strings.settingsTitle))
        .environment(\.locale, appController.localization.locale)
    }

    private var header: some View {
        let strings = appController.localization.strings

        return HStack(alignment: .center, spacing: 18) {
            Image(nsImage: settingsIconImage)
                .resizable()
                .interpolation(.high)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(strings.appName)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(SpeedChrome.textPrimary)

                Text(appController.installedVersionDescription)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(SpeedChrome.textTertiary)
            }

            Spacer(minLength: 16)

            VStack(alignment: .trailing, spacing: 8) {
                scheduleBadge

                Text(appController.nextAutomaticTestDescription)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(SpeedChrome.textSecondary)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 220, alignment: .trailing)
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 22)
    }

    private var settingsIconImage: NSImage {
        if let bundledIcon = AppBundleIconLoader.load() {
            return bundledIcon
        }

        if let runningIcon = NSRunningApplication.current.icon, runningIcon.isValid {
            return runningIcon
        }

        return NSImage(
            systemSymbolName: "gauge.with.needle",
            accessibilityDescription: nil
        ) ?? NSApplication.shared.applicationIconImage
    }

    private var sectionDivider: some View {
        SubtleDivider()
            .padding(.vertical, 18)
    }

    private var scheduleBadge: some View {
        SubtleBadge(
            title: appController.automaticTestInterval.shortTitle(using: appController.localization.strings),
            symbol: appController.automaticTestInterval == .off ? "pause.circle.fill" : "clock.fill",
            tint: appController.automaticTestInterval == .off ? .secondary : SpeedChrome.brand
        )
    }

    private var menuBarPreview: some View {
        HStack(spacing: 6) {
            Image(systemName: appController.speedTestViewModel.menuBarSymbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(SpeedChrome.textSecondary)

            if let menuBarText = appController.speedTestViewModel.menuBarText(
                for: appController.menuBarDisplayMode
            ) {
                Text(menuBarText)
                    .font(.system(size: 11.5, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(SpeedChrome.textPrimary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(SpeedChrome.softFill)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(SpeedChrome.stroke, lineWidth: 0.8)
        )
    }

    private func sectionMessage(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11.5, weight: .medium))
            .foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 12)
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
}

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased())
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(SpeedChrome.textTertiary)
                .tracking(0.9)

            content
        }
    }
}

private struct SettingsRow<Content: View>: View {
    let title: String
    let detail: String?
    @ViewBuilder let content: Content

    init(
        title: String,
        detail: String?,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.detail = detail
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SpeedChrome.textPrimary)

                if let detail, !detail.isEmpty {
                    Text(detail)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(SpeedChrome.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 20)

            content
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .subtleHover(cornerRadius: 12)
    }
}

private struct SettingsActionLabel: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(tint.opacity(0.16), lineWidth: 0.8)
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

private enum AppBundleIconLoader {
    static func load() -> NSImage? {
        if let iconBaseName = Bundle.main.object(forInfoDictionaryKey: "CFBundleIconFile") as? String {
            let normalizedName = iconBaseName.replacingOccurrences(of: ".icns", with: "")

            if let iconURL = Bundle.main.url(forResource: normalizedName, withExtension: "icns"),
               let iconImage = NSImage(contentsOf: iconURL) {
                return iconImage
            }

            if let iconURL = Bundle.main.url(forResource: normalizedName, withExtension: "svg"),
               let iconImage = NSImage(contentsOf: iconURL) {
                return iconImage
            }
        }

        if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let iconImage = NSImage(contentsOf: iconURL) {
            return iconImage
        }

        if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "svg"),
           let iconImage = NSImage(contentsOf: iconURL) {
            return iconImage
        }

        if let developmentIcon = loadDevelopmentIcon() {
            return developmentIcon
        }

        return nil
    }

    private static func loadDevelopmentIcon() -> NSImage? {
        for root in candidateRoots() {
            let icnsURL = root.appendingPathComponent("App/AppIcon.icns")
            if let iconImage = NSImage(contentsOf: icnsURL) {
                return iconImage
            }

            let svgURL = root.appendingPathComponent("App/AppIcon.svg")
            if let iconImage = NSImage(contentsOf: svgURL) {
                return iconImage
            }
        }

        return nil
    }

    private static func candidateRoots() -> [URL] {
        var roots: [URL] = [
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        ]

        var currentURL = Bundle.main.bundleURL.standardizedFileURL

        for _ in 0..<8 {
            roots.append(currentURL)
            let parentURL = currentURL.deletingLastPathComponent()

            if parentURL == currentURL {
                break
            }

            currentURL = parentURL
        }

        var uniquePaths = Set<String>()
        return roots.filter { url in
            uniquePaths.insert(url.path).inserted
        }
    }
}

import Foundation

public enum MenuBarDisplayMode: String, CaseIterable, Identifiable, Sendable {
    case icon
    case download
    case latency
    case downloadAndUpload

    public var id: String {
        rawValue
    }

    public func title(using strings: SpeedStrings) -> String {
        strings.menuBarDisplayModeTitle(self)
    }
}

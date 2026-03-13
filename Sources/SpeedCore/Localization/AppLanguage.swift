import Foundation

public enum SupportedLanguage: String, CaseIterable, Identifiable, Sendable {
    case english = "en"
    case german = "de"

    public var id: String {
        rawValue
    }

    public var locale: Locale {
        Locale(identifier: rawValue)
    }

    public var nativeDisplayName: String {
        switch self {
        case .english:
            "English"
        case .german:
            "Deutsch"
        }
    }

    public static func bestMatch(for preferredLanguages: [String]) -> SupportedLanguage {
        for preferredLanguage in preferredLanguages {
            let normalized = preferredLanguage.lowercased()

            if let exactMatch = allCases.first(where: { $0.rawValue == normalized }) {
                return exactMatch
            }

            if let prefixMatch = allCases.first(
                where: {
                    normalized.hasPrefix($0.rawValue + "-") || normalized.hasPrefix($0.rawValue + "_")
                }
            ) {
                return prefixMatch
            }
        }

        return .english
    }
}

public enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system
    case english
    case german

    public var id: String {
        rawValue
    }

    public func resolvedLanguage(
        preferredLanguages: [String] = Locale.preferredLanguages
    ) -> SupportedLanguage {
        switch self {
        case .system:
            SupportedLanguage.bestMatch(for: preferredLanguages)
        case .english:
            .english
        case .german:
            .german
        }
    }
}

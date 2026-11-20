import Foundation
import Observation

/// The site's four languages. Uzbek is the source text written in the code;
/// the other tables (Resources/I18n, generated from the Android app's tables)
/// are keyed by that Uzbek text.
enum AppLang: String, CaseIterable, Identifiable, Sendable {
    case uz, ru, en, kr

    var id: String { rawValue }
    var code: String { rawValue.uppercased() }
    var flagAsset: String { "flag_\(rawValue)" }

    fileprivate var tableName: String? {
        switch self {
        case .uz: nil
        case .ru: "strings_ru"
        case .en: "strings_en"
        case .kr: "strings_ko"
        }
    }
}

/// Current language, persisted across launches (key "locale", like the site).
/// Views that call `.tr` in their body re-render when `lang` changes, because
/// Observation tracks the read inside `tr`.
@Observable
final class I18n: @unchecked Sendable {
    static let shared = I18n()

    private static let key = "locale"

    private(set) var lang: AppLang

    @ObservationIgnored private var tables: [AppLang: [String: String]] = [:]

    init(lang: AppLang? = nil) {
        self.lang = lang ?? UserDefaults.standard.string(forKey: Self.key).flatMap(AppLang.init(rawValue:)) ?? .uz
    }

    /// Switches the language and remembers it.
    func set(_ lang: AppLang) {
        guard lang != self.lang else { return }
        self.lang = lang
        UserDefaults.standard.set(lang.rawValue, forKey: Self.key)
    }

    /// Uzbek source text -> current language. Unknown text (server data such
    /// as titles and names) comes back unchanged.
    func tr(_ uz: String) -> String {
        let lang = self.lang
        guard let table = table(for: lang) else { return uz }
        if let exact = table[uz] { return exact }
        return templated(uz, table) ?? uz
    }

    private func table(for lang: AppLang) -> [String: String]? {
        guard let name = lang.tableName else { return nil }
        if let cached = tables[lang] { return cached }
        guard
            let url = Bundle.main.url(forResource: name, withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let table = try? JSONDecoder().decode([String: String].self, from: data)
        else { return nil }
        tables[lang] = table
        return table
    }

    private static let number = try! NSRegularExpression(pattern: "\\d+")
    private static let placeholder = try! NSRegularExpression(pattern: "\\{(\\d+)\\}")

    /// "12 mavjud", "1-6 / 20": numbers are swapped for {n} placeholders so
    /// one table entry covers every count.
    private func templated(_ uz: String, _ table: [String: String]) -> String? {
        let ns = uz as NSString
        let matches = Self.number.matches(in: uz, range: NSRange(location: 0, length: ns.length))
        guard !matches.isEmpty else { return nil }
        let numbers = matches.map { ns.substring(with: $0.range) }
        var key = ""
        var last = 0
        for (i, m) in matches.enumerated() {
            key += ns.substring(with: NSRange(location: last, length: m.range.location - last))
            key += "{\(i)}"
            last = m.range.location + m.range.length
        }
        key += ns.substring(from: last)
        guard let template = table[key] else { return nil }
        let tns = template as NSString
        var out = ""
        var pos = 0
        for m in Self.placeholder.matches(in: template, range: NSRange(location: 0, length: tns.length)) {
            out += tns.substring(with: NSRange(location: pos, length: m.range.location - pos))
            let index = Int(tns.substring(with: m.range(at: 1))) ?? 0
            out += index < numbers.count ? numbers[index] : ""
            pos = m.range.location + m.range.length
        }
        out += tns.substring(from: pos)
        return out
    }
}

extension String {
    /// This text in the current language.
    var tr: String { I18n.shared.tr(self) }
}

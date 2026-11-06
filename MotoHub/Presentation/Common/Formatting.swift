import Foundation

/// Uzbek labels for backend enum values, plus price/date/text formatting.
enum Formatting {
    private static let labels: [String: String] = [
        // brands
        "HARLEY_DAVIDSON": "Harley-Davidson", "BMW": "BMW", "UNIVERSAL": "Universal",
        // motorbike types
        "SPORT": "Sport", "CRUISER": "Kruizer", "SCOOTER": "Skuter",
        // conditions
        "NEW": "Yangi", "USED": "Ishlatilgan", "REFURBISHED": "Tiklangan",
        // part categories & types
        "SPARE_PART": "Ehtiyot qism", "ACCESSORY": "Aksessuar",
        "ENGINE": "Dvigatel", "EXHAUST": "Glushitel", "BRAKE": "Tormoz", "SUSPENSION": "Amortizator",
        "TIRE": "Shina", "BATTERY": "Akkumulyator", "FILTER": "Filtr", "CHAIN": "Zanjir",
        "ELECTRICAL": "Elektrika", "BODY_PANEL": "Kuzov detali", "HELMET": "Dubulg‘a",
        "GLOVES": "Qo‘lqop", "JACKET": "Kurtka", "BOOTS": "Botinka", "LUGGAGE": "Yukxalta",
        "PHONE_MOUNT": "Telefon ushlagich", "COVER": "G‘ilof", "OTHER": "Boshqa",
        // regions
        "TASHKENT": "Toshkent", "ANDIJAN": "Andijon", "BUKHARA": "Buxoro", "FERGANA": "Farg‘ona",
        "JIZZAKH": "Jizzax", "KHOREZM": "Xorazm", "NAMANGAN": "Namangan", "NAVOI": "Navoiy",
        "KASHKADARYA": "Qashqadaryo", "SAMARKAND": "Samarqand", "SIRDARYA": "Sirdaryo",
        "SURKHANDARYA": "Surxondaryo", "KARAKALPAKSTAN": "Qoraqalpog‘iston",
    ]

    /// "HONDA" → "Honda", "TASHKENT" → "Toshkent".
    static func label(_ value: String) -> String {
        if let known = labels[value] { return known }
        return value
            .lowercased()
            .split(separator: "_")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    /// 12500 → "12 500".
    static func groupDigits(_ value: Double) -> String {
        let digits = String(Int(value.rounded()))
        var out = ""
        for (index, char) in digits.enumerated() {
            if index > 0, (digits.count - index) % 3 == 0 { out.append(" ") }
            out.append(char)
        }
        return out
    }

    static func price(_ value: Double, currency: String?) -> String {
        switch currency ?? "USD" {
        case "USD": "$\(groupDigits(value))"
        case "UZS": "\(groupDigits(value)) so‘m"
        case "KRW": "₩\(groupDigits(value))"
        case let other: "\(groupDigits(value)) \(other)"
        }
    }

    /// Descriptions come from a rich-text editor; show them as plain text.
    static func plainText(_ html: String?) -> String {
        guard var text = html else { return "" }
        let rules: [(String, String)] = [
            ("<br\\s*/?>", "\n"),
            ("</p>", "\n"),
            ("<[^>]+>", ""),
            ("&nbsp;", " "),
            ("&amp;", "&"),
            ("\n{3,}", "\n\n"),
        ]
        for (pattern, replacement) in rules {
            text = text.replacingOccurrences(of: pattern, with: replacement, options: [.regularExpression, .caseInsensitive])
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func timeAgo(_ date: Date?, now: Date = .now) -> String {
        guard let date else { return "" }
        let minutes = Int(now.timeIntervalSince(date) / 60)
        let hours = minutes / 60
        let days = hours / 24
        if minutes < 60 { return "\(min(max(minutes, 1), 59)) daqiqa oldin" }
        if hours < 24 { return "\(hours) soat oldin" }
        if days < 30 { return "\(days) kun oldin" }
        if days < 365 { return "\(days / 30) oy oldin" }
        return "\(days / 365) yil oldin"
    }
}

import SwiftUI

extension Color {
    /// 0xAARRGGBB, the same notation the Android app and the site's CSS use.
    init(argb: UInt32) {
        self.init(
            .sRGB,
            red: Double((argb >> 16) & 0xFF) / 255,
            green: Double((argb >> 8) & 0xFF) / 255,
            blue: Double(argb & 0xFF) / 255,
            opacity: Double((argb >> 24) & 0xFF) / 255
        )
    }
}

/// MOTOPRESTO brand, taken from the website (motopresto.online).
enum Brand {
    /// Site green: prices, primary buttons, active states.
    static let green = Color(argb: 0xFF25B44B)
    static let greenDark = Color(argb: 0xFF178F38)

    /// Site navbar / footer.
    static let ink = Color(argb: 0xFF181A20)

    /// "Popular / Top" sections on the site.
    static let indigo = Color(argb: 0xFF6366F1)
    static let indigoDark = Color(argb: 0xFF4F46E5)

    /// Floating "AI Assistant" button on the site.
    static let ai = Color(argb: 0xFFE8462B)

    static let page = Color(argb: 0xFFF7F8FA)
    static let muted = Color(argb: 0xFF6B7280)
    static let line = Color(argb: 0xFFE5E7EB)

    /// Light green pills (location row, spec chips on cards).
    static let greenSoft = Color(argb: 0xFFEFF8F1)

    /// The detail pages' green (#4CAF50).
    static let siteGreen = Color(argb: 0xFF4CAF50)

    static let greenGradient = LinearGradient(colors: [green, greenDark], startPoint: .leading, endPoint: .trailing)

    static func gradient(_ colors: [Color]) -> LinearGradient {
        LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
    }
}

extension Font {
    /// The site's font. Weights without a bundled file fall back like Flutter does.
    static func poppins(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .medium: name = "Poppins-Medium"
        case .semibold: name = "Poppins-SemiBold"
        case .bold: name = "Poppins-Bold"
        case .heavy, .black: name = "Poppins-ExtraBold"
        default: name = "Poppins-Regular"
        }
        return .custom(name, size: size)
    }
}

/// The MOTOPRESTO logo, the same file and sizes the website uses
/// (38 navbar, 36 drawer, 48 footer).
struct BrandLogo: View {
    var height: CGFloat = 38

    var body: some View {
        Image("logo")
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .accessibilityLabel("MOTOPRESTO")
    }
}

/// Title-cases every word: "Eng ko'p qidirilgan" -> "Eng Ko'p Qidirilgan".
func titleCase(_ s: String) -> String {
    s.split(separator: " ", omittingEmptySubsequences: false)
        .map { $0.prefix(1).uppercased() + $0.dropFirst() }
        .joined(separator: " ")
}

extension View {
    /// Text painted with a left-to-right gradient (Flutter's ShaderMask).
    func gradientText(_ colors: [Color]) -> some View {
        foregroundStyle(Brand.gradient(colors))
    }

    /// Rounded border, like Flutter's BoxDecoration(border: Border.all(...)).
    func roundedBorder(_ color: Color, radius: CGFloat, width: CGFloat = 1) -> some View {
        overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(color, lineWidth: width))
    }
}

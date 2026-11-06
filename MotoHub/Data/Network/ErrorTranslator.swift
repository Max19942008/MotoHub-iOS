import Foundation

/// The backend speaks English; show the messages users hit most in Uzbek.
enum ErrorTranslator {
    private static let known: [String: String] = [
        "No member with that member nick!": "Bunday nikdagi foydalanuvchi topilmadi.",
        "Wrong password, try again!": "Parol noto‘g‘ri.",
        "Already used nick or phone": "Bu nik yoki telefon raqam allaqachon band.",
        "You have been blocked!": "Hisobingiz bloklangan.",
        "This account signs in with Google!": "Bu hisob Google orqali kiradi — saytdan kiring.",
        "AI assistant is not configured": "AI yordamchi hozircha sozlanmagan.",
        "Assistant is busy, please try again in a minute": "Yordamchi band, bir daqiqadan so‘ng urinib ko‘ring.",
        "Assistant is unavailable right now": "Yordamchi hozir ishlamayapti.",
        "Too many questions — please wait a few minutes": "Juda ko‘p savol — bir necha daqiqa kuting.",
    ]

    static func translate(_ message: String) -> String { known[message] ?? message }
}

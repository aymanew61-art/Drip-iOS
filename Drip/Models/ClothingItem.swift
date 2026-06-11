import SwiftUI

struct ClothingItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var brand: String = ""
    var category: ClothingCategory
    var colorTag: ClothingColor = .black
    var price: Double = 0
    var imageData: Data?
    var timesWorn: Int = 0
    var dateAdded: Date = Date()
    var lastWorn: Date? = nil
    var isFavorite: Bool = false
    var notes: String = ""
    var season: ClothingSeason = .allYear
    var washCount: Int = 0
    var lastWashed: Date? = nil

    var costPerWear: Double {
        guard timesWorn > 0, price > 0 else { return price }
        return price / Double(timesWorn)
    }

    var daysSinceWorn: Int? {
        guard let last = lastWorn else { return nil }
        return Calendar.current.dateComponents([.day], from: last, to: Date()).day
    }

    var isSleeping: Bool {
        guard timesWorn > 0, let days = daysSinceWorn else { return false }
        return days > 30
    }

    var washNeeded: Bool {
        timesWorn - washCount >= 3
    }

    static func == (lhs: ClothingItem, rhs: ClothingItem) -> Bool { lhs.id == rhs.id }
}

enum ClothingCategory: String, CaseIterable, Codable {
    case tops = "Tops"
    case bottoms = "Hosen"
    case shoes = "Schuhe"
    case outerwear = "Jacken"
    case formal = "Formell"
    case accessories = "Accessoires"
    case sportswear = "Sport"

    var icon: String {
        switch self {
        case .tops: return "tshirt.fill"
        case .bottoms: return "rectangle.portrait.fill"
        case .shoes: return "figure.walk"
        case .outerwear: return "cloud.fill"
        case .formal: return "briefcase.fill"
        case .accessories: return "bag.fill"
        case .sportswear: return "figure.run"
        }
    }

    var color: Color {
        switch self {
        case .tops: return Color(red: 0.4, green: 0.6, blue: 1.0)
        case .bottoms: return Color(red: 0.6, green: 0.4, blue: 1.0)
        case .shoes: return Color(red: 1.0, green: 0.55, blue: 0.3)
        case .outerwear: return Color(red: 0.3, green: 0.85, blue: 0.75)
        case .formal: return Color(red: 0.9, green: 0.75, blue: 0.3)
        case .accessories: return Color(red: 1.0, green: 0.4, blue: 0.65)
        case .sportswear: return Color(red: 0.3, green: 0.92, blue: 0.5)
        }
    }

    var sortOrder: Int {
        switch self {
        case .outerwear: return 0
        case .tops: return 1
        case .formal: return 2
        case .bottoms: return 3
        case .shoes: return 4
        case .accessories: return 5
        case .sportswear: return 6
        }
    }
}

enum ClothingColor: String, CaseIterable, Codable {
    case black = "Schwarz"
    case white = "Weiß"
    case gray = "Grau"
    case beige = "Beige"
    case brown = "Braun"
    case red = "Rot"
    case pink = "Pink"
    case orange = "Orange"
    case yellow = "Gelb"
    case green = "Grün"
    case blue = "Blau"
    case navy = "Dunkelblau"
    case purple = "Lila"
    case multicolor = "Bunt"

    var swiftColor: Color {
        switch self {
        case .black: return Color(red: 0.1, green: 0.1, blue: 0.1)
        case .white: return Color(red: 0.95, green: 0.95, blue: 0.95)
        case .gray: return Color(red: 0.6, green: 0.6, blue: 0.6)
        case .beige: return Color(red: 0.9, green: 0.85, blue: 0.75)
        case .brown: return Color(red: 0.55, green: 0.35, blue: 0.2)
        case .red: return Color(red: 0.9, green: 0.2, blue: 0.2)
        case .pink: return Color(red: 1.0, green: 0.5, blue: 0.7)
        case .orange: return Color(red: 1.0, green: 0.6, blue: 0.1)
        case .yellow: return Color(red: 1.0, green: 0.85, blue: 0.1)
        case .green: return Color(red: 0.2, green: 0.75, blue: 0.3)
        case .blue: return Color(red: 0.2, green: 0.5, blue: 1.0)
        case .navy: return Color(red: 0.1, green: 0.15, blue: 0.5)
        case .purple: return Color(red: 0.6, green: 0.2, blue: 0.9)
        case .multicolor: return Color(red: 1.0, green: 0.4, blue: 0.8)
        }
    }
}

enum ClothingSeason: String, CaseIterable, Codable {
    case spring = "Frühling"
    case summer = "Sommer"
    case autumn = "Herbst"
    case winter = "Winter"
    case allYear = "Ganzjährig"

    var icon: String {
        switch self {
        case .spring: return "leaf.fill"
        case .summer: return "sun.max.fill"
        case .autumn: return "wind"
        case .winter: return "snowflake"
        case .allYear: return "infinity"
        }
    }
}

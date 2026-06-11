import Foundation

struct Outfit: Identifiable, Codable {
    var id = UUID()
    var name: String
    var itemIDs: [UUID]
    var occasion: OutfitOccasion = .casual
    var dateCreated: Date = Date()
    var timesWorn: Int = 0
    var isFavorite: Bool = false
    var aiGenerated: Bool = false
    var aiDescription: String = ""
}

enum OutfitOccasion: String, CaseIterable, Codable {
    case casual = "Casual"
    case formal = "Formell"
    case sport = "Sport"
    case party = "Party"
    case work = "Arbeit"
    case date = "Date"

    var icon: String {
        switch self {
        case .casual: return "sun.max.fill"
        case .formal: return "briefcase.fill"
        case .sport: return "figure.run"
        case .party: return "sparkles"
        case .work: return "building.2.fill"
        case .date: return "heart.fill"
        }
    }

    var color: String {
        switch self {
        case .casual: return "orange"
        case .formal: return "blue"
        case .sport: return "green"
        case .party: return "purple"
        case .work: return "gray"
        case .date: return "pink"
        }
    }
}

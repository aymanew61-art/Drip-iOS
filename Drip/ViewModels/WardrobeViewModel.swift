import SwiftUI
import Combine

class WardrobeViewModel: ObservableObject {
    @Published var items: [ClothingItem] = []
    @Published var outfits: [Outfit] = []
    @Published var calendarEntries: [String: UUID] = [:]
    @Published var isGeneratingAI = false
    @Published var aiSuggestedOutfit: Outfit? = nil
    @AppStorage("drip_onboarding_done") var onboardingDone = false
    @AppStorage("drip_style_vibe") var styleVibe = ""

    private let itemsKey    = "drip_items_v2"
    private let outfitsKey  = "drip_outfits_v2"
    private let calendarKey = "drip_calendar_v2"

    init() { load() }

    // MARK: – Items

    func addItem(_ item: ClothingItem) { items.insert(item, at: 0); saveItems() }

    func updateItem(_ item: ClothingItem) {
        if let i = items.firstIndex(where: { $0.id == item.id }) { items[i] = item; saveItems() }
    }

    func deleteItem(_ item: ClothingItem) {
        items.removeAll { $0.id == item.id }
        for i in outfits.indices { outfits[i].itemIDs.removeAll { $0 == item.id } }
        saveItems(); saveOutfits()
    }

    func wearItem(_ item: ClothingItem) {
        if let i = items.firstIndex(where: { $0.id == item.id }) {
            items[i].timesWorn += 1; items[i].lastWorn = Date(); saveItems()
        }
    }

    func markWashed(_ item: ClothingItem) {
        if let i = items.firstIndex(where: { $0.id == item.id }) {
            items[i].washCount = items[i].timesWorn; items[i].lastWashed = Date(); saveItems()
        }
    }

    func toggleFavoriteItem(_ item: ClothingItem) {
        if let i = items.firstIndex(where: { $0.id == item.id }) { items[i].isFavorite.toggle(); saveItems() }
    }

    func items(for category: ClothingCategory) -> [ClothingItem] {
        items.filter { $0.category == category }
    }

    func items(for outfit: Outfit) -> [ClothingItem] {
        outfit.itemIDs.compactMap { id in items.first { $0.id == id } }
            .sorted { $0.category.sortOrder < $1.category.sortOrder }
    }

    func searchItems(_ query: String) -> [ClothingItem] {
        guard !query.isEmpty else { return items }
        let q = query.lowercased()
        return items.filter { $0.name.lowercased().contains(q) || $0.brand.lowercased().contains(q) || $0.category.rawValue.lowercased().contains(q) }
    }

    // MARK: – Outfits

    func addOutfit(_ outfit: Outfit) { outfits.insert(outfit, at: 0); saveOutfits() }
    func deleteOutfit(_ outfit: Outfit) { outfits.removeAll { $0.id == outfit.id }; saveOutfits() }

    func wearOutfit(_ outfit: Outfit) {
        if let i = outfits.firstIndex(where: { $0.id == outfit.id }) {
            outfits[i].timesWorn += 1
            outfit.itemIDs.forEach { id in
                if let j = items.firstIndex(where: { $0.id == id }) {
                    items[j].timesWorn += 1; items[j].lastWorn = Date()
                }
            }
            saveOutfits(); saveItems()
        }
    }

    func toggleFavoriteOutfit(_ outfit: Outfit) {
        if let i = outfits.firstIndex(where: { $0.id == outfit.id }) { outfits[i].isFavorite.toggle(); saveOutfits() }
    }

    // MARK: – Calendar

    func logOutfitForToday(_ outfit: Outfit) {
        calendarEntries[dateKey(for: Date())] = outfit.id
        wearOutfit(outfit); saveCalendar()
    }

    func logOutfit(_ outfit: Outfit, for date: Date) {
        calendarEntries[dateKey(for: date)] = outfit.id; saveCalendar()
    }

    func outfit(for date: Date) -> Outfit? {
        guard let id = calendarEntries[dateKey(for: date)] else { return nil }
        return outfits.first { $0.id == id }
    }

    func hasOutfit(for date: Date) -> Bool { calendarEntries[dateKey(for: date)] != nil }

    func dateKey(for date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: date)
    }

    // MARK: – AI Generator

    func generateAIOutfit(occasion: OutfitOccasion = .casual) {
        isGeneratingAI = true; aiSuggestedOutfit = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
            guard let self else { return }
            self.aiSuggestedOutfit = self.smartSuggestion(occasion: occasion)
            self.isGeneratingAI = false
        }
    }

    private func smartSuggestion(occasion: OutfitOccasion) -> Outfit? {
        let month = Calendar.current.component(.month, from: Date())
        let season: ClothingSeason = { switch month { case 3...5: .spring; case 6...8: .summer; case 9...11: .autumn; default: .winter } }()

        func pick(_ category: ClothingCategory) -> ClothingItem? {
            items.filter { $0.category == category && ($0.season == .allYear || $0.season == season) }
                 .sorted { lhs, rhs in
                     let ls = lhs.timesWorn + (lhs.daysSinceWorn.map { max(0, 30 - $0) } ?? 0)
                     let rs = rhs.timesWorn + (rhs.daysSinceWorn.map { max(0, 30 - $0) } ?? 0)
                     return ls < rs
                 }.first
        }

        var ids: [UUID] = []
        if occasion == .formal { pick(.formal).map { ids.append($0.id) } }
        else { pick(.tops).map { ids.append($0.id) } }
        pick(.bottoms).map { ids.append($0.id) }
        pick(.shoes).map { ids.append($0.id) }
        if [11,12,1,2,3].contains(month) { pick(.outerwear).map { ids.append($0.id) } }
        if let acc = items.filter({ $0.category == .accessories }).randomElement() { ids.append(acc.id) }

        guard !ids.isEmpty else { return nil }
        let tips: [OutfitOccasion: String] = [
            .casual: "Entspannt & stylisch — dein Go-To Look",
            .formal: "Sharp und professionell — du bist ready",
            .sport: "Aktiv und drip — volle Power",
            .party: "All eyes on you tonight",
            .work: "Office-Look auf Punkt",
            .date: "Date-Night vibes — charming & frisch"
        ]
        return Outfit(name: "KI Outfit", itemIDs: ids, occasion: occasion, aiGenerated: true,
                      aiDescription: tips[occasion] ?? "Dein perfekter Look")
    }

    // MARK: – Stats

    var totalValue: Double { items.reduce(0) { $0 + $1.price } }
    var totalItems: Int { items.count }
    var totalOutfits: Int { outfits.count }
    var neverWornItems: [ClothingItem] { items.filter { $0.timesWorn == 0 } }
    var sleepingItems: [ClothingItem] { items.filter { $0.isSleeping } }
    var washNeededItems: [ClothingItem] { items.filter { $0.washNeeded } }
    var mostWornItem: ClothingItem? { items.max(by: { $0.timesWorn < $1.timesWorn }) }

    var wornThisMonthCount: Int {
        guard let start = Calendar.current.dateInterval(of: .month, for: Date())?.start else { return 0 }
        return items.filter { ($0.lastWorn ?? .distantPast) >= start }.count
    }
    var wornThisMonthPercentage: Double {
        guard totalItems > 0 else { return 0 }
        return Double(wornThisMonthCount) / Double(totalItems)
    }
    var avgCostPerWear: Double {
        let w = items.filter { $0.timesWorn > 0 && $0.price > 0 }
        guard !w.isEmpty else { return 0 }
        return w.reduce(0) { $0 + $1.costPerWear } / Double(w.count)
    }
    var categoryBreakdown: [(ClothingCategory, Int)] {
        ClothingCategory.allCases.compactMap { cat in
            let n = items.filter { $0.category == cat }.count
            return n > 0 ? (cat, n) : nil
        }.sorted { $0.1 > $1.1 }
    }
    var colorBreakdown: [(ClothingColor, Int)] {
        ClothingColor.allCases.compactMap { c in
            let n = items.filter { $0.colorTag == c }.count
            return n > 0 ? (c, n) : nil
        }.sorted { $0.1 > $1.1 }
    }
    var priceByCategory: [(ClothingCategory, Double)] {
        ClothingCategory.allCases.compactMap { cat in
            let total = items.filter { $0.category == cat }.reduce(0) { $0 + $1.price }
            return total > 0 ? (cat, total) : nil
        }.sorted { $0.1 > $1.1 }
    }
    func versatilityScore(for item: ClothingItem) -> Int {
        outfits.filter { $0.itemIDs.contains(item.id) }.count
    }

    // MARK: – Streak

    var currentStreak: Int {
        var streak = 0
        var date = Calendar.current.startOfDay(for: Date())
        while hasOutfit(for: date) {
            streak += 1
            guard let prev = Calendar.current.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
        }
        return streak
    }

    // MARK: – Daily Challenge

    var dailyChallenge: String {
        let challenges = [
            "Trage etwas, das du 30+ Tage nicht getragen hast 🌙",
            "Monochrom-Look: Alles in einer Farbe 🎨",
            "Trage dein teuerstes Kleidungsstück 💎",
            "Kombiniere 2 Farben, die du normalerweise nicht kombinierst 🔀",
            "Trage das Stück mit dem besten Preis/Tragen-Verhältnis 💡",
            "Trage etwas von deiner Saisonkleidung 🌿",
            "Baue ein Outfit nur aus Favorites ❤️",
            "Trage dein am häufigsten getragenes Outfit erneut 🔁"
        ]
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let day = dayOfYear % challenges.count
        return challenges[day]
    }

    // MARK: – Week

    var currentWeekDates: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let daysFromMon = (weekday + 5) % 7
        guard let monday = cal.date(byAdding: .day, value: -daysFromMon, to: today) else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
    }

    // MARK: – Persistence

    private func load() {
        if let d = UserDefaults.standard.data(forKey: itemsKey),
           let v = try? JSONDecoder().decode([ClothingItem].self, from: d) { items = v }
        if let d = UserDefaults.standard.data(forKey: outfitsKey),
           let v = try? JSONDecoder().decode([Outfit].self, from: d) { outfits = v }
        if let d = UserDefaults.standard.data(forKey: calendarKey),
           let v = try? JSONDecoder().decode([String: UUID].self, from: d) { calendarEntries = v }
    }
    private func saveItems()   { if let d = try? JSONEncoder().encode(items)   { UserDefaults.standard.set(d, forKey: itemsKey) } }
    private func saveOutfits() { if let d = try? JSONEncoder().encode(outfits) { UserDefaults.standard.set(d, forKey: outfitsKey) } }
    private func saveCalendar(){ if let d = try? JSONEncoder().encode(calendarEntries) { UserDefaults.standard.set(d, forKey: calendarKey) } }
}

private extension Calendar {
    func component(_ component: Calendar.Component, from date: Date) -> Int {
        self.dateComponents([component], from: date).value(for: component) ?? 0
    }
}

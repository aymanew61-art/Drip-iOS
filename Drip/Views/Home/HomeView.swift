import SwiftUI

struct HomeView: View {
    @EnvironmentObject var vm: WardrobeViewModel
    @State private var showAdd = false
    @State private var showAI = false

    private var hour: Int { Calendar.current.component(.hour, from: Date()) }
    private var greeting: String {
        if hour < 12 { return "Guten Morgen" }
        if hour < 18 { return "Guten Tag" }
        return "Guten Abend"
    }
    private var dateStr: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "de_DE")
        f.dateFormat = "EEEE, d. MMMM"; return f.string(from: Date())
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                AppTheme.bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        header
                        Divider().background(AppTheme.stroke2)
                        if vm.currentStreak > 1 { streakRow }
                        todaySection
                        if !vm.washNeededItems.isEmpty { washRow }
                        weekStrip
                        challengeRow
                        statsRow
                        if !vm.items.isEmpty { recentSection }
                        if !vm.sleepingItems.isEmpty { sleepingSection }
                        Spacer(minLength: 90)
                    }
                }
                addFAB
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAdd) { AddItemView() }
            .sheet(isPresented: $showAI) { AIOutfitGeneratorView() }
        }
    }

    // MARK: – Header

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting).font(.system(size: 13)).foregroundColor(AppTheme.textTertiary)
                Text("Drip").font(.system(size: 36, weight: .black)).foregroundColor(.white)
                Text(dateStr).font(.system(size: 12)).foregroundColor(AppTheme.textTertiary)
            }
            Spacer()
            Button { showAI = true } label: {
                Image(systemName: "sparkles").font(.system(size: 17))
                    .foregroundColor(.black)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.accent)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 18)
    }

    // MARK: – Streak

    private var streakRow: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text("🔥").font(.system(size: 18))
                Text("\(vm.currentStreak)-Tage Streak").font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                Spacer()
                Text("Jeden Tag ein Outfit geloggt").font(.system(size: 12)).foregroundColor(AppTheme.textTertiary)
            }
            .padding(.horizontal, 20).padding(.vertical, 12)
            .background(AppTheme.surface)
            Divider().background(AppTheme.stroke2)
        }
    }

    // MARK: – Today

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("LOOK DES TAGES")
            if let outfit = vm.outfit(for: Date()) {
                let its = vm.items(for: outfit)
                Button { } label: {
                    HStack(spacing: 14) {
                        StackedOutfitCollage(items: its).frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 5) {
                            Text(outfit.name).font(.system(size: 16, weight: .semibold)).foregroundColor(.white)
                            Text(outfit.occasion.rawValue).font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)
                            Text("\(its.count) Teile").font(.system(size: 11))
                                .foregroundColor(AppTheme.textTertiary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 12))
                            .foregroundColor(AppTheme.textTertiary)
                    }
                    .padding(.horizontal, 20).padding(.vertical, 14)
                }
            } else {
                Button { showAI = true } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "sparkles").font(.system(size: 22)).foregroundColor(AppTheme.textTertiary)
                            .frame(width: 50, height: 50).background(AppTheme.surface2)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Kein Look geplant").font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                            Text("KI Outfit generieren").font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(AppTheme.textTertiary)
                    }
                    .padding(.horizontal, 20).padding(.vertical, 14)
                }
            }
            Divider().background(AppTheme.stroke2)
        }
    }

    // MARK: – Wash

    private var washRow: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "drop").font(.system(size: 14)).foregroundColor(.white)
                Text("\(vm.washNeededItems.count) Teile müssen gewaschen werden")
                    .font(.system(size: 13, weight: .medium)).foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 20).padding(.vertical, 12)
            .background(AppTheme.surface)
            Divider().background(AppTheme.stroke2)
        }
    }

    // MARK: – Week Strip

    private var weekStrip: some View {
        VStack(spacing: 0) {
            sectionHeader("DIESE WOCHE")
            let days = vm.currentWeekDates
            let labels = ["Mo","Di","Mi","Do","Fr","Sa","So"]
            let today = Calendar.current.startOfDay(for: Date())
            HStack(spacing: 0) {
                ForEach(Array(days.enumerated()), id: \.offset) { i, date in
                    let isToday = Calendar.current.isDate(date, inSameDayAs: today)
                    let has = vm.hasOutfit(for: date)
                    VStack(spacing: 5) {
                        Text(labels[i]).font(.system(size: 10)).foregroundColor(AppTheme.textTertiary)
                        ZStack {
                            Circle()
                                .fill(isToday ? AppTheme.accent : (has ? AppTheme.surface2 : .clear))
                                .frame(width: 30, height: 30)
                            if has && !isToday {
                                Circle().stroke(AppTheme.stroke, lineWidth: 1).frame(width: 30, height: 30)
                                Image(systemName: "checkmark").font(.system(size: 9, weight: .bold))
                                    .foregroundColor(AppTheme.green)
                            } else {
                                Text("\(Calendar.current.component(.day, from: date))")
                                    .font(.system(size: 12, weight: isToday ? .bold : .regular))
                                    .foregroundColor(isToday ? .black : AppTheme.textSecondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 14)
            Divider().background(AppTheme.stroke2)
        }
    }

    // MARK: – Challenge

    private var challengeRow: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("⚡").font(.system(size: 16))
                VStack(alignment: .leading, spacing: 2) {
                    Text("CHALLENGE").font(.system(size: 9, weight: .semibold)).foregroundColor(AppTheme.textTertiary).kerning(1.5)
                    Text(vm.dailyChallenge).font(.system(size: 13)).foregroundColor(.white).lineLimit(2)
                }
                Spacer()
            }
            .padding(.horizontal, 20).padding(.vertical, 14)
            Divider().background(AppTheme.stroke2)
        }
    }

    // MARK: – Stats Row

    private var statsRow: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                statCell("\(vm.totalItems)", "Klamotten")
                Divider().frame(height: 36).background(AppTheme.stroke2)
                statCell("\(vm.totalOutfits)", "Outfits")
                Divider().frame(height: 36).background(AppTheme.stroke2)
                statCell("\(Int(vm.wornThisMonthPercentage * 100))%", "diesen Monat")
            }
            .padding(.vertical, 16)
            Divider().background(AppTheme.stroke2)
        }
    }

    private func statCell(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 20, weight: .bold)).foregroundColor(.white)
            Text(label).font(.system(size: 10)).foregroundColor(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: – Recent

    private var recentSection: some View {
        VStack(spacing: 0) {
            sectionHeader("ZULETZT HINZUGEFÜGT")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 1) {
                    ForEach(vm.items.prefix(12)) { item in
                        NavigationLink(destination: ItemDetailView(item: item)) {
                            recentThumb(item)
                        }
                    }
                }
            }
            Divider().background(AppTheme.stroke2)
        }
    }

    private func recentThumb(_ item: ClothingItem) -> some View {
        ZStack(alignment: .bottom) {
            ClothingThumbnail(item: item, size: 110)
                .frame(width: 110, height: 140)
            LinearGradient(colors: [.clear, Color.black.opacity(0.7)],
                           startPoint: .center, endPoint: .bottom).frame(height: 60)
            Text(item.name).font(.system(size: 10, weight: .medium)).foregroundColor(.white)
                .lineLimit(1).padding(.horizontal, 6).padding(.bottom, 6)
        }
        .frame(width: 110, height: 140)
    }

    // MARK: – Sleeping

    private var sleepingSection: some View {
        VStack(spacing: 0) {
            sectionHeader("SEIT 30+ TAGEN NICHT GETRAGEN")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 1) {
                    ForEach(vm.sleepingItems.prefix(8)) { item in
                        NavigationLink(destination: ItemDetailView(item: item)) {
                            recentThumb(item)
                        }
                    }
                }
            }
            Divider().background(AppTheme.stroke2)
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        HStack {
            Text(text).font(.system(size: 9, weight: .semibold)).foregroundColor(AppTheme.textTertiary).kerning(1.5)
            Spacer()
        }
        .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 10)
    }

    private var addFAB: some View {
        Button { showAdd = true } label: {
            Image(systemName: "plus").font(.system(size: 20, weight: .semibold)).foregroundColor(.black)
                .frame(width: 54, height: 54).background(AppTheme.accent).clipShape(Circle())
                .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
        }
        .padding(.trailing, 20).padding(.bottom, 20)
    }
}

// Shared
struct RecentItemCard: View {
    let item: ClothingItem
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ClothingThumbnail(item: item, size: 100)
            Text(item.name).font(.caption).fontWeight(.semibold).foregroundColor(.white).lineLimit(1)
        }.frame(width: 106)
    }
}
struct SleepingItemCard: View {
    let item: ClothingItem
    var body: some View {
        VStack(spacing: 5) {
            ClothingThumbnail(item: item, size: 80)
            Text(item.name).font(.caption2).foregroundColor(AppTheme.textSecondary).lineLimit(1).frame(width: 80)
        }
    }
}
struct OutfitFlatlay: View {
    let items: [ClothingItem]; let size: CGFloat
    var body: some View {
        StackedOutfitCollage(items: items).frame(width: size, height: size).clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

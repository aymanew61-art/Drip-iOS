import SwiftUI

struct OutfitCalendarView: View {
    @EnvironmentObject var vm: WardrobeViewModel
    @State private var selectedDate = Date()
    @State private var showOutfitPicker = false
    @State private var displayedMonth = Date()

    private var calendar: Calendar { Calendar.current }
    private var monthDates: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }
        let weekday = (calendar.component(.weekday, from: firstDay) + 5) % 7
        var dates: [Date?] = Array(repeating: nil, count: weekday)
        for day in range {
            if let d = calendar.date(byAdding: .day, value: day - 1, to: firstDay) { dates.append(d) }
        }
        return dates
    }

    private var monthLabel: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "de_DE"); f.dateFormat = "MMMM yyyy"
        return f.string(from: displayedMonth)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        monthHeader
                        weekdayLabels
                        calendarGrid
                        selectedDayDetail
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 16).padding(.top, 8)
                }
            }
            .navigationTitle("Outfit Kalender")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppTheme.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showOutfitPicker) {
                CalendarOutfitPickerView(date: selectedDate)
            }
        }
    }

    // MARK: – Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
            } label: {
                Image(systemName: "chevron.left").foregroundColor(.white).font(.title3)
                    .frame(width: 36, height: 36).glassCard(cornerRadius: 10)
            }
            Spacer()
            Text(monthLabel)
                .font(.title3).fontWeight(.bold).foregroundColor(.white)
            Spacer()
            Button {
                displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
            } label: {
                Image(systemName: "chevron.right").foregroundColor(.white).font(.title3)
                    .frame(width: 36, height: 36).glassCard(cornerRadius: 10)
            }
        }
    }

    // MARK: – Weekday Labels

    private var weekdayLabels: some View {
        HStack {
            ForEach(["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"], id: \.self) { d in
                Text(d).font(.system(size: 11, weight: .medium)).foregroundColor(.white.opacity(0.35))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: – Calendar Grid

    private var calendarGrid: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
        return LazyVGrid(columns: cols, spacing: 6) {
            ForEach(Array(monthDates.enumerated()), id: \.offset) { _, date in
                if let date {
                    calendarCell(for: date)
                } else {
                    Color.clear.frame(height: 44)
                }
            }
        }
    }

    private func calendarCell(for date: Date) -> some View {
        let isToday = calendar.isDateInToday(date)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let hasOutfit = vm.hasOutfit(for: date)
        let day = calendar.component(.day, from: date)
        let isFuture = date > Date()

        return Button { selectedDate = date } label: {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.accent)
                } else if isToday {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppTheme.accent, lineWidth: 1.5)
                        .background(AppTheme.accent.opacity(0.1).clipShape(RoundedRectangle(cornerRadius: 10)))
                } else if hasOutfit {
                    RoundedRectangle(cornerRadius: 10).fill(AppTheme.green.opacity(0.18))
                } else {
                    RoundedRectangle(cornerRadius: 10).fill(AppTheme.surface)
                }

                VStack(spacing: 2) {
                    Text("\(day)").font(.system(size: 13, weight: isToday || isSelected ? .bold : .regular))
                        .foregroundColor(isFuture && !isSelected ? .white.opacity(0.35) : .white)
                    if hasOutfit {
                        Circle().fill(isSelected ? .white : AppTheme.green).frame(width: 4, height: 4)
                    }
                }
            }
            .frame(height: 46)
        }
    }

    // MARK: – Selected Day Detail

    @ViewBuilder
    private var selectedDayDetail: some View {
        let dayOutfit = vm.outfit(for: selectedDate)
        let dayStr = selectedDate.formatted(date: .complete, time: .omitted)
        let isToday = calendar.isDateInToday(selectedDate)
        let isPast = selectedDate < calendar.startOfDay(for: Date())

        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(isToday ? "Heute" : dayStr)
                    .font(.headline).foregroundColor(.white)
                Spacer()
                if dayOutfit != nil || isToday || !isPast {
                    Button {
                        showOutfitPicker = true
                    } label: {
                        Label(dayOutfit != nil ? "Ändern" : "Outfit hinzufügen", systemImage: dayOutfit != nil ? "pencil" : "plus")
                            .font(.caption).fontWeight(.semibold)
                            .foregroundColor(AppTheme.accent)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .glassCard(cornerRadius: 10)
                    }
                }
            }

            if let outfit = dayOutfit {
                let items = vm.items(for: outfit)
                HStack(spacing: 14) {
                    OutfitFlatlay(items: items, size: 90)
                    VStack(alignment: .leading, spacing: 6) {
                        if outfit.aiGenerated {
                            Label("KI Outfit", systemImage: "sparkles")
                                .font(.caption2).foregroundStyle(AppTheme.accent)
                        }
                        Text(outfit.name).font(.headline).fontWeight(.bold).foregroundColor(.white)
                        Text(outfit.occasion.rawValue).font(.caption)
                            .foregroundColor(AppTheme.accent).padding(.horizontal, 10).padding(.vertical, 3)
                            .background(AppTheme.accent.opacity(0.15)).clipShape(Capsule())
                        Text("\(items.count) Teile").font(.caption2).foregroundColor(.white.opacity(0.4))
                    }
                    Spacer()
                }
            } else {
                HStack(spacing: 12) {
                    Image(systemName: isPast ? "calendar.badge.minus" : "calendar.badge.plus")
                        .font(.title2).foregroundColor(.white.opacity(0.25))
                    Text(isPast ? "Kein Outfit an diesem Tag" : "Kein Outfit geplant")
                        .font(.subheadline).foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
            }
        }
        .padding(16).glassCard()
    }
}

struct CalendarOutfitPickerView: View {
    @EnvironmentObject var vm: WardrobeViewModel
    @Environment(\.dismiss) var dismiss
    let date: Date

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                if vm.outfits.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.square").font(.system(size: 50))
                            .foregroundStyle(AppTheme.accent)
                        Text("Noch keine Outfits").font(.title3).fontWeight(.semibold).foregroundColor(.white)
                        Text("Erstelle zuerst ein Outfit im Outfits-Tab")
                            .font(.subheadline).foregroundColor(.white.opacity(0.45)).multilineTextAlignment(.center)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(vm.outfits) { outfit in
                                Button {
                                    vm.logOutfitForToday(outfit)
                                    dismiss()
                                } label: {
                                    CalendarOutfitRow(outfit: outfit)
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Outfit wählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }.foregroundColor(.white.opacity(0.55))
                }
            }
        }
    }
}

struct CalendarOutfitRow: View {
    @EnvironmentObject var vm: WardrobeViewModel
    let outfit: Outfit

    var body: some View {
        let items = vm.items(for: outfit)
        HStack(spacing: 14) {
            OutfitFlatlay(items: items, size: 60)
            VStack(alignment: .leading, spacing: 4) {
                if outfit.aiGenerated {
                    Label("KI", systemImage: "sparkles").font(.caption2).foregroundStyle(AppTheme.accent)
                }
                Text(outfit.name).font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                Text(outfit.occasion.rawValue).font(.caption).foregroundColor(AppTheme.accent)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.white.opacity(0.3))
        }
        .padding(14).glassCard()
    }
}

import SwiftUI

struct StatsView: View {
    @EnvironmentObject var vm: WardrobeViewModel
    @State private var animate = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                if vm.items.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "chart.bar").font(.system(size: 48)).foregroundColor(AppTheme.textTertiary)
                        Text("Noch keine Daten").font(.title3).fontWeight(.semibold).foregroundColor(.white)
                        Text("Füge Klamotten hinzu").font(.subheadline).foregroundColor(AppTheme.textSecondary)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            overviewGrid
                            Divider().background(AppTheme.stroke2)
                            categorySection
                            Divider().background(AppTheme.stroke2)
                            colorSection
                            Divider().background(AppTheme.stroke2)
                            if !vm.priceByCategory.isEmpty { priceSection; Divider().background(AppTheme.stroke2) }
                            if !vm.sleepingItems.isEmpty { sleepingSection; Divider().background(AppTheme.stroke2) }
                            topWornSection
                            if !vm.neverWornItems.isEmpty { Divider().background(AppTheme.stroke2); neverWornSection }
                            Divider().background(AppTheme.stroke2)
                            costSection
                            Spacer(minLength: 80)
                        }
                    }
                }
            }
            .navigationTitle("Statistiken")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(AppTheme.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear { withAnimation(.easeOut(duration: 1.0)) { animate = true } }
        }
    }

    private var overviewGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 0) {
            statCell(value: Double(vm.totalItems), fmt: "%.0f", label: "Klamotten", divider: true)
            statCell(value: vm.wornThisMonthPercentage * 100, fmt: "%.0f%%", label: "Getragen", divider: true)
            statCell(value: vm.totalValue, fmt: "%.0f €", label: "Gesamt-Wert", divider: false)
        }
        .padding(.vertical, 20)
    }

    private func statCell(value: Double, fmt: String, label: String, divider: Bool) -> some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                CountUp(to: value, fmt: fmt)
                    .font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                Text(label).font(.system(size: 11)).foregroundColor(AppTheme.textTertiary)
            }
            .frame(maxWidth: .infinity)
            if divider { Divider().frame(height: 36).background(AppTheme.stroke2) }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("KATEGORIEN")
            let bd = vm.categoryBreakdown; let maxC = bd.first?.1 ?? 1
            ForEach(bd, id: \.0) { cat, count in
                HStack(spacing: 10) {
                    Image(systemName: cat.icon).font(.system(size: 13)).foregroundColor(AppTheme.textTertiary).frame(width: 18)
                    Text(cat.rawValue).font(.system(size: 13)).foregroundColor(.white).frame(width: 80, alignment: .leading)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3).fill(AppTheme.surface2)
                            RoundedRectangle(cornerRadius: 3).fill(AppTheme.accent.opacity(0.7))
                                .frame(width: animate ? geo.size.width * CGFloat(count)/CGFloat(maxC) : 0)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animate)
                        }
                    }.frame(height: 6)
                    Text("\(count)").font(.system(size: 12)).foregroundColor(AppTheme.textTertiary).frame(width: 20, alignment: .trailing)
                }
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 18)
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("FARBPALETTE")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(vm.colorBreakdown, id: \.0) { c, n in
                        VStack(spacing: 5) {
                            ZStack {
                                Circle().fill(c.swiftColor).frame(width: 34, height: 34)
                                    .overlay(Circle().stroke(AppTheme.stroke, lineWidth: 0.5))
                                Text("\(n)").font(.system(size: 9, weight: .bold))
                                    .foregroundColor(c == .white || c == .yellow || c == .beige ? Color.black : .white)
                            }
                            Text(c.rawValue).font(.system(size: 9)).foregroundColor(AppTheme.textTertiary).frame(width: 40).lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 18)
    }

    private var priceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("AUSGABEN NACH KATEGORIE")
            let bd = vm.priceByCategory; let maxV = bd.first?.1 ?? 1
            ForEach(bd, id: \.0) { cat, total in
                HStack(spacing: 10) {
                    Text(cat.rawValue).font(.system(size: 13)).foregroundColor(.white).frame(width: 80, alignment: .leading)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3).fill(AppTheme.surface2)
                            RoundedRectangle(cornerRadius: 3).fill(AppTheme.accent.opacity(0.5))
                                .frame(width: animate ? geo.size.width * CGFloat(total/maxV) : 0)
                                .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1), value: animate)
                        }
                    }.frame(height: 6)
                    Text(String(format: "%.0f €", total)).font(.system(size: 12)).foregroundColor(AppTheme.textTertiary).frame(width: 50, alignment: .trailing)
                }
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 18)
    }

    private var sleepingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("SEIT 30+ TAGEN NICHT GETRAGEN")
                Spacer()
                Text("\(vm.sleepingItems.count)").font(.system(size: 12, weight: .semibold)).foregroundColor(AppTheme.textSecondary)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(vm.sleepingItems.prefix(8)) { item in
                        NavigationLink(destination: ItemDetailView(item: item)) {
                            VStack(spacing: 5) {
                                ClothingThumbnail(item: item, size: 80)
                                Text(item.name).font(.system(size: 10)).foregroundColor(AppTheme.textSecondary).lineLimit(1).frame(width: 80)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 18)
    }

    @ViewBuilder private var topWornSection: some View {
        let top = vm.items.filter { $0.timesWorn > 0 }.sorted { $0.timesWorn > $1.timesWorn }.prefix(5)
        VStack(alignment: .leading, spacing: 0) {
            sectionTitle("MEISTGETRAGEN").padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 12)
            ForEach(Array(top.enumerated()), id: \.element.id) { i, item in
                NavigationLink(destination: ItemDetailView(item: item)) {
                    HStack(spacing: 14) {
                        Text("\(i+1)").font(.system(size: 12)).foregroundColor(AppTheme.textTertiary).frame(width: 16)
                        ClothingThumbnail(item: item, size: 50).clipShape(RoundedRectangle(cornerRadius: 7))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.name).font(.system(size: 14, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                            Text(item.category.rawValue).font(.system(size: 11)).foregroundColor(AppTheme.textSecondary)
                        }
                        Spacer()
                        Text("\(item.timesWorn)×").font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    }
                    .padding(.horizontal, 20).padding(.vertical, 12)
                }
                if i < top.count - 1 { Divider().background(AppTheme.stroke2).padding(.leading, 70) }
            }
        }
    }

    @ViewBuilder private var neverWornSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("NIE GETRAGEN")
                Spacer()
                Text("\(vm.neverWornItems.count)").font(.system(size: 12, weight: .semibold)).foregroundColor(AppTheme.textSecondary)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(vm.neverWornItems.prefix(8)) { item in
                        NavigationLink(destination: ItemDetailView(item: item)) {
                            VStack(spacing: 5) {
                                ClothingThumbnail(item: item, size: 80)
                                Text(item.name).font(.system(size: 10)).foregroundColor(AppTheme.textSecondary).lineLimit(1).frame(width: 80)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 18)
    }

    @ViewBuilder private var costSection: some View {
        let best = vm.items.filter { $0.timesWorn > 0 && $0.price > 0 }.sorted { $0.costPerWear < $1.costPerWear }.prefix(5)
        if !best.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                sectionTitle("BESTER PREIS/TRAGEN").padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 12)
                ForEach(best) { item in
                    NavigationLink(destination: ItemDetailView(item: item)) {
                        HStack(spacing: 14) {
                            ClothingThumbnail(item: item, size: 46).clipShape(RoundedRectangle(cornerRadius: 7))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.name).font(.system(size: 14, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                                Text("\(item.timesWorn)× • \(String(format: "%.0f €", item.price))").font(.system(size: 11)).foregroundColor(AppTheme.textSecondary)
                            }
                            Spacer()
                            Text(String(format: "%.2f €", item.costPerWear)).font(.system(size: 14, weight: .bold)).foregroundColor(AppTheme.green)
                        }
                        .padding(.horizontal, 20).padding(.vertical, 12)
                    }
                }
            }
        }
    }

    private func sectionTitle(_ t: String) -> some View {
        Text(t).font(.system(size: 9, weight: .semibold)).foregroundColor(AppTheme.textTertiary).kerning(1.5)
    }
}

// Compat
struct RingChart: View {
    let percentage: Double; let color: Color; let size: CGFloat; let label: String
    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.1), lineWidth: 10)
            Circle().trim(from: 0, to: min(percentage, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 1) {
                Text("\(Int(min(percentage,1)*100))%").font(.system(size: size * 0.18, weight: .bold)).foregroundColor(.white)
                Text(label).font(.system(size: size * 0.09)).foregroundColor(AppTheme.textTertiary).multilineTextAlignment(.center)
            }
        }.frame(width: size, height: size)
    }
}
struct ValueCard: View {
    let title: String; let value: Double; let format: String; let icon: String; let color: Color
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(String(format: format, value)).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                Text(title).font(.caption2).foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(14).frame(maxWidth: .infinity).glassCard()
    }
}

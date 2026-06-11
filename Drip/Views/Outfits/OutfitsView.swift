import SwiftUI

struct OutfitsView: View {
    @EnvironmentObject var vm: WardrobeViewModel
    @State private var showBuilder = false
    @State private var showAI = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                AppTheme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    aiBanner
                    Divider().background(AppTheme.stroke2)
                    if vm.outfits.isEmpty { emptyState }
                    else { outfitGrid }
                }
                addFAB
            }
            .navigationTitle("Outfits (\(vm.totalOutfits))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showBuilder) { OutfitBuilderView() }
            .sheet(isPresented: $showAI) { AIOutfitGeneratorView() }
        }
    }

    private var aiBanner: some View {
        Button { showAI = true } label: {
            HStack(spacing: 14) {
                Image(systemName: "sparkles").font(.system(size: 16)).foregroundColor(.black)
                    .frame(width: 38, height: 38).background(AppTheme.accent).clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("KI Outfit Generator").font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                    Text("Outfit aus deinem Schrank generieren").font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(AppTheme.textTertiary)
            }
            .padding(.horizontal, 20).padding(.vertical, 14)
        }
    }

    private var outfitGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 1), GridItem(.flexible(), spacing: 1)], spacing: 1) {
                ForEach(vm.outfits) { outfit in
                    NavigationLink(destination: OutfitDetailView(outfit: outfit)) {
                        OutfitGridCell(outfit: outfit)
                    }
                    .contextMenu {
                        Button { vm.logOutfitForToday(outfit) } label: { Label("Heute getragen", systemImage: "checkmark") }
                        Button { vm.toggleFavoriteOutfit(outfit) } label: {
                            Label(outfit.isFavorite ? "Favorit entfernen" : "Favorit", systemImage: "heart")
                        }
                        Button(role: .destructive) { vm.deleteOutfit(outfit) } label: { Label("Löschen", systemImage: "trash") }
                    }
                }
            }
            .padding(.bottom, 90)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "person.crop.square").font(.system(size: 48)).foregroundColor(AppTheme.textTertiary)
            Text("Noch keine Outfits").font(.title3).fontWeight(.semibold).foregroundColor(.white)
            Text("Tippe + oder nutze den KI Generator").font(.subheadline).foregroundColor(AppTheme.textSecondary)
            Spacer()
        }.frame(maxWidth: .infinity)
    }

    private var addFAB: some View {
        Button { showBuilder = true } label: {
            Image(systemName: "plus").font(.system(size: 20, weight: .semibold)).foregroundColor(.black)
                .frame(width: 54, height: 54).background(AppTheme.accent).clipShape(Circle())
                .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
        }
        .padding(.trailing, 20).padding(.bottom, 20)
    }
}

struct OutfitGridCell: View {
    let outfit: Outfit
    @EnvironmentObject var vm: WardrobeViewModel

    var body: some View {
        let items = vm.items(for: outfit)
        ZStack(alignment: .bottom) {
            StackedOutfitCollage(items: items).frame(maxWidth: .infinity).frame(height: 220)
            LinearGradient(colors: [.clear, Color.black.opacity(0.8)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 3) {
                if outfit.aiGenerated {
                    Image(systemName: "sparkles").font(.system(size: 10)).foregroundColor(AppTheme.accent)
                }
                Text(outfit.name).font(.system(size: 13, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                Text(outfit.occasion.rawValue).font(.system(size: 11)).foregroundColor(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10).padding(.bottom, 10)
        }
        .aspectRatio(3/4, contentMode: .fit)
    }
}

struct OutfitDetailView: View {
    @EnvironmentObject var vm: WardrobeViewModel
    @Environment(\.dismiss) var dismiss
    let outfit: Outfit
    private var cur: Outfit { vm.outfits.first { $0.id == outfit.id } ?? outfit }

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    StackedOutfitCollage(items: vm.items(for: cur))
                        .frame(maxWidth: .infinity).frame(height: 340)
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                if cur.aiGenerated { Label("KI Look", systemImage: "sparkles").font(.system(size: 11)).foregroundColor(AppTheme.accent) }
                                Text(cur.name).font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                                Text(cur.occasion.rawValue).font(.subheadline).foregroundColor(AppTheme.textSecondary)
                            }
                            Spacer()
                            Button { vm.toggleFavoriteOutfit(outfit) } label: {
                                Image(systemName: cur.isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 18)).foregroundColor(cur.isFavorite ? .white : AppTheme.textTertiary)
                            }
                        }
                        .padding(.horizontal, 20).padding(.vertical, 20)

                        if cur.aiGenerated && !cur.aiDescription.isEmpty {
                            Text(cur.aiDescription).font(.subheadline).foregroundColor(AppTheme.textSecondary)
                                .padding(.horizontal, 20).padding(.bottom, 16)
                        }

                        Divider().background(AppTheme.stroke2)
                        ForEach(vm.items(for: cur)) { item in
                            NavigationLink(destination: ItemDetailView(item: item)) {
                                HStack(spacing: 14) {
                                    ClothingThumbnail(item: item, size: 56).clipShape(RoundedRectangle(cornerRadius: 8))
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.name).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                                        Text(item.category.rawValue).font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(AppTheme.textTertiary)
                                }
                                .padding(.horizontal, 20).padding(.vertical, 14)
                            }
                            Divider().background(AppTheme.stroke2).padding(.leading, 90)
                        }

                        Button { vm.logOutfitForToday(cur) } label: {
                            Text("Heute tragen")
                                .font(.system(size: 16, weight: .semibold)).foregroundColor(.black)
                                .frame(maxWidth: .infinity).padding(.vertical, 16)
                                .background(AppTheme.accent).clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .pressScale()
                        .padding(.horizontal, 20).padding(.top, 24).padding(.bottom, 40)
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct StackedOutfitCollage: View {
    let items: [ClothingItem]
    var body: some View {
        let sorted = items.sorted { $0.category.sortOrder < $1.category.sortOrder }
        GeometryReader { geo in
            let w = geo.size.width; let h = geo.size.height
            ZStack { AppTheme.surface
                if sorted.isEmpty {
                    Image(systemName: "person.crop.square").font(.system(size: 40)).foregroundColor(AppTheme.textTertiary)
                } else if sorted.count == 1 {
                    img(sorted[0]).frame(width: w, height: h)
                } else if sorted.count == 2 {
                    HStack(spacing: 1) {
                        img(sorted[0]).frame(width: w/2, height: h)
                        img(sorted[1]).frame(width: w/2, height: h)
                    }
                } else {
                    HStack(spacing: 1) {
                        img(sorted[0]).frame(width: w * 0.5, height: h)
                        VStack(spacing: 1) {
                            ForEach(Array(sorted.dropFirst().prefix(3)), id: \.id) { item in
                                img(item).frame(width: w*0.5, height: h / CGFloat(min(sorted.count-1, 3)))
                            }
                        }.frame(width: w * 0.5)
                    }
                }
            }
        }
    }
    private func img(_ item: ClothingItem) -> some View {
        Group {
            if let d = item.imageData, let ui = UIImage(data: d) {
                Image(uiImage: ui).resizable().scaledToFill().clipped()
            } else {
                ZStack {
                    AppTheme.surface2
                    Image(systemName: item.category.icon).font(.system(size: 20)).foregroundColor(AppTheme.textTertiary)
                }
            }
        }
    }
}

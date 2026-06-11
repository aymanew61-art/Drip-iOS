import SwiftUI

struct WardrobeView: View {
    @EnvironmentObject var vm: WardrobeViewModel
    @State private var search = ""
    @State private var filterCat: ClothingCategory? = nil
    @State private var cols = 3
    @State private var showAdd = false

    private var items: [ClothingItem] {
        var r = vm.searchItems(search)
        if let c = filterCat { r = r.filter { $0.category == c } }
        return r
    }
    private var grid: [GridItem] { Array(repeating: GridItem(.flexible(), spacing: 1), count: cols) }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                AppTheme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    searchBar
                    categoryBar
                    Divider().background(AppTheme.stroke2)
                    if items.isEmpty { emptyState }
                    else { grid_view }
                }
                addFAB
            }
            .navigationTitle("Schrank (\(vm.totalItems))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { cols = cols == 3 ? 2 : 3 } label: {
                        Image(systemName: cols == 3 ? "square.grid.2x2" : "square.grid.3x3")
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showAdd) { AddItemView() }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").font(.system(size: 14))
                .foregroundColor(AppTheme.textTertiary)
            TextField("Suchen…", text: $search)
                .foregroundColor(.white).tint(AppTheme.accent)
            if !search.isEmpty {
                Button { search = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                catChip(nil, "Alles")
                ForEach(ClothingCategory.allCases, id: \.self) { c in
                    if !vm.items(for: c).isEmpty { catChip(c, c.rawValue) }
                }
            }
            .padding(.horizontal, 14).padding(.bottom, 10)
        }
    }

    private func catChip(_ cat: ClothingCategory?, _ label: String) -> some View {
        let sel = filterCat == cat
        return Button { filterCat = cat } label: {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(sel ? .black : AppTheme.textSecondary)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(sel ? AppTheme.accent : AppTheme.surface2)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(sel ? .clear : AppTheme.stroke2, lineWidth: 1))
        }
    }

    private var grid_view: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: grid, spacing: 1) {
                ForEach(items) { item in
                    NavigationLink(destination: ItemDetailView(item: item)) {
                        ItemCell(item: item, size: cols)
                    }
                    .contextMenu {
                        Button { vm.wearItem(item) } label: { Label("Heute getragen", systemImage: "checkmark") }
                        Button { vm.toggleFavoriteItem(item) } label: {
                            Label(item.isFavorite ? "Favorit entfernen" : "Favorit", systemImage: "heart")
                        }
                        Button(role: .destructive) { vm.deleteItem(item) } label: { Label("Löschen", systemImage: "trash") }
                    }
                }
            }
            .padding(.bottom, 90)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "tshirt").font(.system(size: 48)).foregroundColor(AppTheme.textTertiary)
            Text(search.isEmpty ? "Noch leer" : "Keine Treffer")
                .font(.title3).fontWeight(.semibold).foregroundColor(.white)
            if search.isEmpty {
                Button { showAdd = true } label: {
                    Text("Erstes Stück hinzufügen")
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundColor(.black)
                        .padding(.horizontal, 20).padding(.vertical, 12)
                        .background(AppTheme.accent).clipShape(Capsule())
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var addFAB: some View {
        Button { showAdd = true } label: {
            Image(systemName: "plus").font(.system(size: 20, weight: .semibold))
                .foregroundColor(.black)
                .frame(width: 54, height: 54)
                .background(AppTheme.accent)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
        }
        .padding(.trailing, 20).padding(.bottom, 20)
    }
}

struct ItemCell: View {
    let item: ClothingItem
    let size: Int

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            itemImage
            if item.isFavorite {
                Image(systemName: "heart.fill").font(.system(size: 9))
                    .foregroundColor(.white).padding(4)
                    .background(Color.black.opacity(0.55)).clipShape(Circle())
                    .padding(5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
        .aspectRatio(3/4, contentMode: .fit)
    }

    private var itemImage: some View {
        Group {
            if let data = item.imageData, let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                ZStack {
                    AppTheme.surface
                    VStack(spacing: 6) {
                        Image(systemName: item.category.icon)
                            .font(.system(size: size == 2 ? 32 : 22))
                            .foregroundColor(AppTheme.textTertiary)
                        if size == 2 {
                            Text(item.name).font(.caption2).foregroundColor(AppTheme.textTertiary)
                                .lineLimit(1).padding(.horizontal, 8)
                        }
                    }
                }
            }
        }
        .clipped()
    }
}

// Shared thumbnail (used across views)
struct ClothingThumbnail: View {
    let item: ClothingItem
    let size: CGFloat

    var body: some View {
        Group {
            if let data = item.imageData, let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFill()
            } else {
                ZStack {
                    AppTheme.thumbBg
                    Image(systemName: item.category.icon)
                        .font(.system(size: size == .infinity ? 28 : size * 0.32))
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
        }
        .frame(width: size == .infinity ? nil : size, height: size == .infinity ? nil : size)
        .clipShape(RoundedRectangle(cornerRadius: size == .infinity ? 0 : 10))
    }
}

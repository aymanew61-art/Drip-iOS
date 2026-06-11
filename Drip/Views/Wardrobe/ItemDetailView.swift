import SwiftUI
import PhotosUI

struct ItemDetailView: View {
    @EnvironmentObject var vm: WardrobeViewModel
    @Environment(\.dismiss) var dismiss
    let item: ClothingItem

    @State private var showDelete = false
    @State private var showEdit = false

    private var cur: ClothingItem { vm.items.first { $0.id == item.id } ?? item }

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroPhoto
                    infoSection
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEdit = true } label: { Label("Bearbeiten", systemImage: "pencil") }
                    Button { vm.toggleFavoriteItem(cur) } label: {
                        Label(cur.isFavorite ? "Favorit entfernen" : "Favorit",
                              systemImage: cur.isFavorite ? "heart.slash" : "heart")
                    }
                    Button { vm.markWashed(cur) } label: { Label("Gewaschen", systemImage: "drop") }
                    Divider()
                    Button(role: .destructive) { showDelete = true } label: { Label("Löschen", systemImage: "trash") }
                } label: { Image(systemName: "ellipsis").foregroundColor(.white) }
            }
        }
        .alert("Löschen?", isPresented: $showDelete) {
            Button("Löschen", role: .destructive) { vm.deleteItem(item); dismiss() }
            Button("Abbrechen", role: .cancel) {}
        }
        .sheet(isPresented: $showEdit) { EditItemView(item: cur) }
    }

    // MARK: – Hero

    private var heroPhoto: some View {
        ZStack(alignment: .bottom) {
            Group {
                if let data = cur.imageData, let ui = UIImage(data: data) {
                    Image(uiImage: ui).resizable().scaledToFit()
                        .frame(maxWidth: .infinity)
                } else {
                    ZStack {
                        AppTheme.surface
                        Image(systemName: cur.category.icon)
                            .font(.system(size: 80)).foregroundColor(AppTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity).frame(height: 360)
                }
            }
            LinearGradient(colors: [.clear, AppTheme.bg.opacity(0.95)],
                           startPoint: .center, endPoint: .bottom).frame(height: 160)
        }
    }

    // MARK: – Info

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Title
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(cur.category.rawValue.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(AppTheme.textTertiary)
                        .kerning(2)
                    Circle().fill(cur.colorTag.swiftColor).frame(width: 10, height: 10)
                        .overlay(Circle().stroke(AppTheme.stroke, lineWidth: 0.5))
                }
                Text(cur.name).font(.system(size: 26, weight: .bold)).foregroundColor(.white)
                if !cur.brand.isEmpty {
                    Text(cur.brand).font(.subheadline).foregroundColor(AppTheme.textSecondary)
                }
            }

            // Stats row
            HStack(spacing: 10) {
                statPill("\(cur.timesWorn)×", "Getragen")
                if cur.price > 0 { statPill(String(format: "%.0f €", cur.price), "Kaufpreis") }
                if cur.timesWorn > 0 && cur.price > 0 {
                    statPill(String(format: "%.2f €", cur.costPerWear), "Pro Tragen")
                }
                if let d = cur.daysSinceWorn {
                    statPill("vor \(d)d", "Zuletzt")
                }
            }

            // Wash alert
            if cur.washNeeded {
                HStack(spacing: 10) {
                    Image(systemName: "drop.fill").foregroundColor(.white)
                    Text("Bitte waschen — \(cur.timesWorn - cur.washCount)× seit letztem Waschen")
                        .font(.subheadline).foregroundColor(.white)
                    Spacer()
                    Button { vm.markWashed(cur) } label: {
                        Text("Ok").font(.caption).fontWeight(.semibold).foregroundColor(.black)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(AppTheme.accent).clipShape(Capsule())
                    }
                }
                .padding(14)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.stroke, lineWidth: 1))
            }

            // Wear button
            Button { vm.wearItem(item) } label: {
                Text("Heute getragen")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(AppTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .pressScale()

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 20).padding(.top, 16)
    }

    private func statPill(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 15, weight: .bold)).foregroundColor(.white)
            Text(label).font(.system(size: 10)).foregroundColor(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.stroke2, lineWidth: 1))
    }
}

struct EditItemView: View {
    @EnvironmentObject var vm: WardrobeViewModel
    @Environment(\.dismiss) var dismiss
    @State var item: ClothingItem
    @State private var priceText: String
    @State private var selectedPhoto: PhotosPickerItem? = nil

    init(item: ClothingItem) {
        _item = State(initialValue: item)
        _priceText = State(initialValue: item.price > 0 ? String(format: "%.2f", item.price) : "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 0) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Group {
                                if let data = item.imageData, let ui = UIImage(data: data) {
                                    Image(uiImage: ui).resizable().scaledToFit().frame(maxWidth: .infinity).frame(maxHeight: 300)
                                } else {
                                    HStack { Image(systemName: "photo"); Text("Foto ändern") }
                                        .foregroundColor(AppTheme.textSecondary).frame(height: 80)
                                }
                            }
                        }
                        .onChange(of: selectedPhoto) { _, new in
                            Task {
                                if let d = try? await new?.loadTransferable(type: Data.self),
                                   let ui = UIImage(data: d) { item.imageData = ui.jpegData(compressionQuality: 0.8) }
                            }
                        }
                        Divider().background(AppTheme.stroke2)
                        editRow("Name", text: $item.name)
                        Divider().background(AppTheme.stroke2).padding(.leading, 20)
                        editRow("Marke", text: $item.brand)
                        Divider().background(AppTheme.stroke2).padding(.leading, 20)
                        editRow("Preis (€)", text: $priceText)
                        Divider().background(AppTheme.stroke2).padding(.leading, 20)
                        editRow("Notizen", text: $item.notes)
                    }
                }
            }
            .navigationTitle("Bearbeiten").navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.bg, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }.foregroundColor(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        item.price = Double(priceText.replacingOccurrences(of: ",", with: ".")) ?? 0
                        vm.updateItem(item); dismiss()
                    }.foregroundColor(AppTheme.accent).fontWeight(.semibold)
                }
            }
        }
    }

    private func editRow(_ label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label).font(.system(size: 15)).foregroundColor(AppTheme.textSecondary).frame(width: 80, alignment: .leading)
            TextField(label, text: text).foregroundColor(.white).tint(AppTheme.accent)
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
    }
}

import SwiftUI
import PhotosUI

struct AddItemView: View {
    @EnvironmentObject var vm: WardrobeViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var brand = ""
    @State private var category: ClothingCategory = .tops
    @State private var colorTag: ClothingColor = .black
    @State private var priceText = ""
    @State private var imageData: Data? = nil
    @State private var selectedPhoto: PhotosPickerItem? = nil

    // URL import
    @State private var urlText = ""
    @State private var isImporting = false
    @State private var importError = false

    // BG removal
    @State private var isRemovingBG = false

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        photoArea
                        Divider().background(AppTheme.stroke2)
                        formArea
                        Spacer(minLength: 100)
                    }
                }
                VStack {
                    Spacer()
                    saveBar
                }
            }
            .navigationTitle("Hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
    }

    // MARK: – Photo Area

    private var photoArea: some View {
        ZStack {
            if let data = imageData, let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable().scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 340)
                    .background(AppTheme.surface)
                    .overlay(alignment: .bottom) { photoOverlayBar }
            } else {
                VStack(spacing: 20) {
                    urlImportRow
                    Divider().background(AppTheme.stroke2).padding(.horizontal, 32)
                    HStack(spacing: 12) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            photoPickerButton(icon: "photo", label: "Galerie")
                        }
                        Button { } label: {
                            photoPickerButton(icon: "camera", label: "Kamera")
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(AppTheme.surface)
            }
        }
        .onChange(of: selectedPhoto) { _, new in
            Task {
                if let data = try? await new?.loadTransferable(type: Data.self),
                   let ui = UIImage(data: data) {
                    imageData = ui.jpegData(compressionQuality: 0.8)
                }
            }
        }
    }

    private func photoPickerButton(icon: String, label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 15))
            Text(label).font(.subheadline).fontWeight(.medium)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppTheme.surface2)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.stroke, lineWidth: 1))
    }

    // MARK: – URL Import

    private var urlImportRow: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "link").font(.system(size: 13)).foregroundColor(AppTheme.textSecondary)
                Text("Von URL importieren").font(.subheadline).fontWeight(.medium).foregroundColor(.white)
            }
            HStack(spacing: 8) {
                TextField("https://www.zara.com/...", text: $urlText)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .tint(AppTheme.accent)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal, 12).padding(.vertical, 10)
                    .background(AppTheme.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(importError ? AppTheme.red : AppTheme.stroke2, lineWidth: 1))

                Button {
                    Task { await importFromURL() }
                } label: {
                    Group {
                        if isImporting {
                            ProgressView().progressViewStyle(.circular).tint(.black).scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.down.circle.fill").font(.system(size: 15))
                        }
                    }
                    .foregroundColor(.black)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(urlText.isEmpty || isImporting)
            }
            if importError {
                Text("Kein Bild gefunden. Versuche einen anderen Link.")
                    .font(.caption).foregroundColor(AppTheme.red)
            }
        }
        .padding(.horizontal, 20)
    }

    private func importFromURL() async {
        importError = false
        isImporting = true
        let result = await URLImportService.fetch(urlString: urlText)
        await MainActor.run {
            isImporting = false
            if let data = result.imageData {
                imageData = data
                if !result.name.isEmpty && name.isEmpty { name = result.name }
                if !result.brand.isEmpty && brand.isEmpty { brand = result.brand }
                if result.price > 0 && priceText.isEmpty { priceText = String(format: "%.2f", result.price) }
            } else {
                importError = true
            }
        }
    }

    // MARK: – Photo overlay

    private var photoOverlayBar: some View {
        HStack(spacing: 8) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                iconPill("photo", "Ändern")
            }
            Button {
                Task { await removeBG() }
            } label: {
                if isRemovingBG {
                    iconPill("wand.and.sparkles", "Lädt…")
                } else {
                    iconPill("wand.and.sparkles", "BG entfernen")
                }
            }
            .disabled(isRemovingBG)
            if imageData != nil {
                Button { imageData = nil } label: {
                    iconPill("trash", "Löschen")
                }
            }
        }
        .padding(.bottom, 12).padding(.horizontal, 16)
    }

    private func iconPill(_ icon: String, _ label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 11))
            Text(label).font(.caption).fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Color.black.opacity(0.6))
        .clipShape(Capsule())
    }

    private func removeBG() async {
        guard let data = imageData, let ui = UIImage(data: data) else { return }
        isRemovingBG = true
        if #available(iOS 17.0, *) {
            let result = await BackgroundRemover.removeBackground(from: ui)
            if let png = result.pngData() { imageData = png }
        }
        isRemovingBG = false
    }

    // MARK: – Form

    private var formArea: some View {
        VStack(spacing: 0) {
            cleanField(icon: "tag", placeholder: "Name *", text: $name)
            divider
            cleanField(icon: "building.2", placeholder: "Marke", text: $brand)
            divider
            cleanField(icon: "eurosign", placeholder: "Preis (€)", text: $priceText)
            divider
            categoryRow
            divider
            colorRow
        }
    }

    private func cleanField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(AppTheme.textTertiary).frame(width: 20)
            TextField(placeholder, text: text)
                .foregroundColor(.white).tint(AppTheme.accent)
                .font(.system(size: 15))
        }
        .padding(.horizontal, 20).padding(.vertical, 16)
    }

    private var divider: some View {
        Divider().background(AppTheme.stroke2).padding(.leading, 54)
    }

    private var categoryRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: "folder").font(.system(size: 14)).foregroundColor(AppTheme.textTertiary).frame(width: 20)
                Text("Kategorie").font(.system(size: 15)).foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 20).padding(.top, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ClothingCategory.allCases, id: \.self) { cat in
                        Button { category = cat } label: {
                            Text(cat.rawValue)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(category == cat ? .black : AppTheme.textSecondary)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(category == cat ? AppTheme.accent : AppTheme.surface2)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(category == cat ? .clear : AppTheme.stroke2, lineWidth: 1))
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 16)
            }
        }
    }

    private var colorRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: "circle.fill").font(.system(size: 14)).foregroundColor(AppTheme.textTertiary).frame(width: 20)
                Text("Farbe").font(.system(size: 15)).foregroundColor(.white)
                Spacer()
                Text(colorTag.rawValue).font(.system(size: 13)).foregroundColor(AppTheme.textSecondary)
            }
            .padding(.horizontal, 20).padding(.top, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ClothingColor.allCases, id: \.self) { c in
                        Button { colorTag = c } label: {
                            ZStack {
                                Circle().fill(c.swiftColor).frame(width: 32, height: 32)
                                    .overlay(Circle().stroke(colorTag == c ? .white : Color.clear, lineWidth: 2))
                                if colorTag == c {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(c == .white || c == .yellow || c == .beige ? Color.black : .white)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 16)
            }
        }
    }

    // MARK: – Save

    private var saveBar: some View {
        Button {
            let price = Double(priceText.replacingOccurrences(of: ",", with: ".")) ?? 0
            let item = ClothingItem(
                name: name.trimmingCharacters(in: .whitespaces),
                brand: brand.trimmingCharacters(in: .whitespaces),
                category: category, colorTag: colorTag,
                price: price, imageData: imageData
            )
            vm.addItem(item)
            dismiss()
        } label: {
            Text("Hinzufügen")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(canSave ? .black : AppTheme.textTertiary)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(canSave ? AppTheme.accent : AppTheme.surface2)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!canSave)
        .padding(.horizontal, 20).padding(.vertical, 16)
        .background(AppTheme.bg)
    }
}

// Shared text field (kept for other views)
struct DripTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(AppTheme.textTertiary).frame(width: 20)
            TextField(placeholder, text: $text).foregroundColor(.white).tint(AppTheme.accent)
        }
        .padding(14).dripCard()
    }
}

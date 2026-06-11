import SwiftUI

struct OutfitBuilderView: View {
    @EnvironmentObject var vm: WardrobeViewModel
    @Environment(\.dismiss) var dismiss

    @State private var outfitName = ""
    @State private var selectedOccasion: OutfitOccasion = .casual
    @State private var selectedIDs: Set<UUID> = []
    @State private var activeCategory: ClothingCategory = .tops
    @State private var step = 0

    private var canSave: Bool { !outfitName.trimmingCharacters(in: .whitespaces).isEmpty && !selectedIDs.isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    stepIndicator
                    if step == 0 { itemSelectionStep }
                    else { namingStep }
                    bottomBar
                }
            }
            .navigationTitle("Outfit erstellen")
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

    // MARK: – Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach([0, 1], id: \.self) { i in
                Capsule()
                    .fill(step >= i ? AnyShapeStyle(AppTheme.accent) : AnyShapeStyle(AppTheme.surface))
                    .frame(height: 4)
                    .animation(.spring(), value: step)
            }
        }
        .padding(.horizontal, 16).padding(.top, 8)
    }

    // MARK: – Step 0: Item Selection

    private var itemSelectionStep: some View {
        VStack(spacing: 0) {
            // Selected preview
            if !selectedIDs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(selectedIDs), id: \.self) { id in
                            if let item = vm.items.first(where: { $0.id == id }) {
                                ZStack(alignment: .topTrailing) {
                                    ClothingThumbnail(item: item, size: 62)
                                    Button { selectedIDs.remove(id) } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 16)).foregroundColor(.white)
                                            .background(Color.black.opacity(0.5)).clipShape(Circle())
                                    }
                                    .offset(x: 4, y: -4)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                }
                .background(AppTheme.surface)
            } else {
                Text("Tippe auf Klamotten zum Auswählen")
                    .font(.caption).foregroundColor(.white.opacity(0.35))
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(AppTheme.surface)
            }

            // Category tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ClothingCategory.allCases.filter { !vm.items(for: $0).isEmpty }, id: \.self) { cat in
                        Button { activeCategory = cat } label: {
                            let sel = activeCategory == cat
                            Text(cat.rawValue).font(.system(size: 12, weight: .medium))
                                .foregroundColor(sel ? .black : AppTheme.textSecondary)
                                .padding(.horizontal, 12).padding(.vertical, 7)
                                .background(sel ? AppTheme.accent : AppTheme.surface2)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
            }

            Divider().background(AppTheme.stroke2)

            // Item picker grid
            let catItems = vm.items(for: activeCategory)
            if catItems.isEmpty {
                Text("Keine \(activeCategory.rawValue)").foregroundColor(.white.opacity(0.35)).padding(.top, 40)
                    .frame(maxWidth: .infinity)
            } else {
                let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
                ScrollView {
                    LazyVGrid(columns: cols, spacing: 8) {
                        ForEach(catItems) { item in
                            let sel = selectedIDs.contains(item.id)
                            Button {
                                if sel { selectedIDs.remove(item.id) }
                                else { selectedIDs.insert(item.id) }
                            } label: {
                                ZStack(alignment: .topTrailing) {
                                    ClothingThumbnail(item: item, size: .infinity)
                                        .aspectRatio(1, contentMode: .fit)
                                        .opacity(sel ? 1 : 0.65)
                                        .overlay(RoundedRectangle(cornerRadius: 12)
                                            .stroke(sel ? AppTheme.accent : Color.clear, lineWidth: 2.5))
                                    if sel {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppTheme.accent)
                                            .background(Color.black.opacity(0.5)).clipShape(Circle())
                                            .padding(4)
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
    }

    // MARK: – Step 1: Naming

    private var namingStep: some View {
        VStack(spacing: 20) {
            // Preview
            let previewItems = Array(selectedIDs).compactMap { id in vm.items.first { $0.id == id } }
            StackedOutfitCollage(items: previewItems)
                .frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 16).padding(.top, 16)

            Text("\(selectedIDs.count) Teile ausgewählt")
                .font(.caption).foregroundColor(.white.opacity(0.45))

            VStack(spacing: 14) {
                DripTextField(placeholder: "Outfit Name *", text: $outfitName, icon: "tag.fill")

                VStack(alignment: .leading, spacing: 10) {
                    Label("Anlass", systemImage: "calendar").font(.caption).fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.5))
                    let cols = Array(repeating: GridItem(.flexible()), count: 3)
                    LazyVGrid(columns: cols, spacing: 8) {
                        ForEach(OutfitOccasion.allCases, id: \.self) { occ in
                            Button { selectedOccasion = occ } label: {
                                let sel = selectedOccasion == occ
                                VStack(spacing: 5) {
                                    Image(systemName: occ.icon).font(.title3)
                                        .foregroundColor(sel ? .white : .white.opacity(0.45))
                                    Text(occ.rawValue).font(.caption2).fontWeight(.medium)
                                        .foregroundColor(sel ? .white : .white.opacity(0.4))
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(sel ? AppTheme.accent.opacity(0.25) : AppTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .stroke(sel ? AppTheme.accent.opacity(0.65) : AppTheme.stroke2, lineWidth: 1))
                            }
                        }
                    }
                }
                .padding(14).glassCard()
            }
            .padding(.horizontal, 16)
            Spacer()
        }
    }

    // MARK: – Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider().background(AppTheme.stroke2)
            HStack(spacing: 12) {
                if step > 0 {
                    Button { withAnimation { step -= 1 } } label: {
                        Text("Zurück").fontWeight(.semibold).foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .glassCard(cornerRadius: 14)
                    }
                }
                Button {
                    if step == 0 {
                        withAnimation { step = 1 }
                    } else {
                        let outfit = Outfit(name: outfitName, itemIDs: Array(selectedIDs), occasion: selectedOccasion)
                        vm.addOutfit(outfit)
                        dismiss()
                    }
                } label: {
                    Text(step == 0 ? "Weiter (\(selectedIDs.count))" : "Outfit speichern")
                        .fontWeight(.semibold).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(selectedIDs.isEmpty ? AppTheme.surface2 : AppTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(step == 0 ? selectedIDs.isEmpty : !canSave)
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            .background(AppTheme.bg)
        }
    }
}

import SwiftUI

struct DressMeView: View {
    @EnvironmentObject var vm: WardrobeViewModel
    @State private var indices: [Int: Int] = [:]   // slotIndex → itemIndex
    @State private var pinned: Set<Int> = []
    @State private var showSave = false
    @State private var saveName = ""

    struct Slot { let index: Int; let label: String; let category: ClothingCategory }
    private let slots = [
        Slot(index: 0, label: "TOP",    category: .tops),
        Slot(index: 1, label: "HOSEN",  category: .bottoms),
        Slot(index: 2, label: "SCHUHE", category: .shoes),
        Slot(index: 3, label: "JACKE",  category: .outerwear),
        Slot(index: 4, label: "EXTRAS", category: .accessories)
    ]
    private var activeSlots: [Slot] { slots.filter { !vm.items(for: $0.category).isEmpty } }

    private func item(for slot: Slot) -> ClothingItem? {
        let list = vm.items(for: slot.category)
        guard !list.isEmpty else { return nil }
        return list[(indices[slot.index] ?? 0) % list.count]
    }
    private var selectedItems: [ClothingItem] { activeSlots.compactMap { item(for: $0) } }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                AppTheme.bg.ignoresSafeArea()
                if vm.items.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "tshirt").font(.system(size: 48)).foregroundColor(AppTheme.textTertiary)
                        Text("Schrank ist leer").font(.title3).fontWeight(.semibold).foregroundColor(.white)
                        Text("Füge Klamotten hinzu").font(.subheadline).foregroundColor(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            titleBar
                            Divider().background(AppTheme.stroke2)
                            ForEach(activeSlots, id: \.index) { slot in
                                slotRow(slot)
                                Divider().background(AppTheme.stroke2)
                            }
                            Spacer(minLength: 100)
                        }
                    }
                    bottomBar
                }
            }
            .navigationBarHidden(true)
            .onAppear { randomizeAll() }
            .sheet(isPresented: $showSave) { saveSheet }
        }
    }

    // MARK: – Title Bar

    private var titleBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("DRESS ME").font(.system(size: 11, weight: .semibold)).foregroundColor(AppTheme.textTertiary).kerning(2)
                Text("Swipen & kombinieren").font(.system(size: 24, weight: .black)).foregroundColor(.white)
            }
            Spacer()
            Button { randomizeAll() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "shuffle").font(.system(size: 13, weight: .semibold))
                    Text("Shuffle").font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 14).padding(.vertical, 9)
                .background(AppTheme.accent).clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 16)
    }

    // MARK: – Slot Row

    private func slotRow(_ slot: Slot) -> some View {
        let list = vm.items(for: slot.category)
        let isPinned = pinned.contains(slot.index)
        let idx = Binding<Int>(
            get: { (indices[slot.index] ?? 0) % max(1, list.count) },
            set: { indices[slot.index] = $0 }
        )

        return VStack(spacing: 0) {
            // Header
            HStack {
                Text(slot.label).font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppTheme.textTertiary).kerning(1.5)
                Text("(\(list.count))").font(.system(size: 10)).foregroundColor(AppTheme.textTertiary)
                Spacer()
                Button {
                    if isPinned { pinned.remove(slot.index) } else { pinned.insert(slot.index) }
                } label: {
                    Image(systemName: isPinned ? "pin.fill" : "pin").font(.system(size: 13))
                        .foregroundColor(isPinned ? .white : AppTheme.textTertiary)
                }
                .frame(width: 36, height: 36)
            }
            .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, 8)

            // Swipeable slot
            if list.isEmpty {
                Text("Keine \(slot.label)").font(.system(size: 13)).foregroundColor(AppTheme.textTertiary)
                    .frame(height: 180)
            } else {
                TabView(selection: idx) {
                    ForEach(Array(list.enumerated()), id: \.element.id) { i, item in
                        slotCard(item, isPinned: isPinned).tag(i).padding(.horizontal, 20)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .frame(height: 180)
            }
        }
    }

    private func slotCard(_ item: ClothingItem, isPinned: Bool) -> some View {
        HStack(spacing: 14) {
            // Large image
            Group {
                if let data = item.imageData, let ui = UIImage(data: data) {
                    Image(uiImage: ui).resizable().scaledToFill()
                } else {
                    ZStack {
                        AppTheme.surface2
                        Image(systemName: item.category.icon).font(.system(size: 32)).foregroundColor(AppTheme.textTertiary)
                    }
                }
            }
            .frame(width: 130, height: 155).clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isPinned ? AppTheme.accent : .clear, lineWidth: 2)
            )

            // Info
            VStack(alignment: .leading, spacing: 8) {
                Text(item.name).font(.system(size: 15, weight: .semibold)).foregroundColor(.white).lineLimit(2)
                if !item.brand.isEmpty {
                    Text(item.brand).font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                }
                HStack(spacing: 5) {
                    Circle().fill(item.colorTag.swiftColor).frame(width: 10, height: 10)
                        .overlay(Circle().stroke(AppTheme.stroke, lineWidth: 0.5))
                    Text(item.colorTag.rawValue).font(.system(size: 11)).foregroundColor(AppTheme.textSecondary)
                }
                if item.timesWorn > 0 {
                    Text("\(item.timesWorn)× getragen").font(.system(size: 11)).foregroundColor(AppTheme.textTertiary)
                }
                if isPinned {
                    Label("Gepinnt", systemImage: "pin.fill").font(.system(size: 10, weight: .medium))
                        .foregroundColor(AppTheme.accent)
                }
            }
            Spacer()
        }
    }

    // MARK: – Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [AppTheme.bg.opacity(0), AppTheme.bg], startPoint: .top, endPoint: .bottom)
                .frame(height: 24)
            HStack(spacing: 12) {
                HStack(spacing: -8) {
                    ForEach(selectedItems.prefix(4)) { item in
                        Group {
                            if let d = item.imageData, let ui = UIImage(data: d) {
                                Image(uiImage: ui).resizable().scaledToFill()
                            } else {
                                ZStack { AppTheme.surface2; Image(systemName: item.category.icon).font(.system(size: 10)).foregroundColor(AppTheme.textTertiary) }
                            }
                        }
                        .frame(width: 32, height: 32).clipShape(Circle())
                        .overlay(Circle().stroke(AppTheme.bg, lineWidth: 2))
                    }
                }
                Text("\(selectedItems.count) Teile").font(.system(size: 13)).foregroundColor(AppTheme.textSecondary)
                Spacer()
                Button { showSave = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bookmark").font(.system(size: 13, weight: .semibold))
                        Text("Speichern").font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.black).padding(.horizontal, 18).padding(.vertical, 11)
                    .background(AppTheme.accent).clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 14)
            .background(AppTheme.bg)
        }
    }

    // MARK: – Save Sheet

    private var saveSheet: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    StackedOutfitCollage(items: selectedItems).frame(maxWidth: .infinity).frame(height: 260)
                    Divider().background(AppTheme.stroke2)
                    HStack {
                        Text("Name").font(.system(size: 15)).foregroundColor(AppTheme.textSecondary).frame(width: 60)
                        TextField("Outfit Name", text: $saveName).foregroundColor(.white).tint(AppTheme.accent)
                    }
                    .padding(.horizontal, 20).padding(.vertical, 16)
                    Divider().background(AppTheme.stroke2)
                    Button {
                        let outfit = Outfit(name: saveName.isEmpty ? "Dress Me Look" : saveName,
                                           itemIDs: selectedItems.map(\.id), occasion: .casual)
                        vm.addOutfit(outfit); showSave = false
                    } label: {
                        Text("Als Outfit speichern").font(.system(size: 16, weight: .semibold)).foregroundColor(.black)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(AppTheme.accent).clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 20).padding(.top, 20)
                    Spacer()
                }
            }
            .navigationTitle("Outfit speichern").navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.bg, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .cancellationAction) {
                Button("Abbrechen") { showSave = false }.foregroundColor(AppTheme.textSecondary)
            }}
        }
    }

    private func randomizeAll() {
        for slot in activeSlots where !pinned.contains(slot.index) {
            let list = vm.items(for: slot.category)
            if !list.isEmpty { indices[slot.index] = Int.random(in: 0..<list.count) }
        }
    }
}

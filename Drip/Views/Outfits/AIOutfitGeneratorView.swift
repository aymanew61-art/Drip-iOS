import SwiftUI

struct AIOutfitGeneratorView: View {
    @EnvironmentObject var vm: WardrobeViewModel
    @Environment(\.dismiss) var dismiss

    @State private var selectedOccasion: OutfitOccasion = .casual
    @State private var saved = false
    @State private var pulseAnim = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        heroHeader
                        occasionGrid
                        generateButton
                        if vm.isGeneratingAI { loadingState }
                        else if let outfit = vm.aiSuggestedOutfit { resultCard(outfit) }
                        else if vm.items.isEmpty { noItemsHint }
                        Spacer(minLength: 80)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("KI Outfit Generator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.bg, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }.foregroundColor(.white.opacity(0.55))
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.8).repeatForever()) { pulseAnim = true }
            }
        }
    }

    // MARK: – Hero

    private var heroHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(AppTheme.accent).frame(width: 60, height: 60)
                    .blur(radius: 20).opacity(pulseAnim ? 0.6 : 0.3)
                    .scaleEffect(pulseAnim ? 1.3 : 1.0)
                Image(systemName: "sparkles").font(.system(size: 44)).foregroundStyle(AppTheme.accent)
            }
            .frame(height: 70)

            Text("KI Outfit Generator").font(.title2).fontWeight(.black).foregroundColor(.white)
            Text("Wähle einen Anlass — die KI analysiert deinen Schrank und baut den perfekten Look")
                .font(.subheadline).foregroundColor(.white.opacity(0.5)).multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: – Occasion Grid

    private var occasionGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FÜR WELCHEN ANLASS?")
                .font(.system(size: 10, weight: .semibold)).foregroundColor(.white.opacity(0.35)).kerning(1.5)

            let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
            LazyVGrid(columns: cols, spacing: 10) {
                ForEach(OutfitOccasion.allCases, id: \.self) { occ in
                    Button { selectedOccasion = occ } label: {
                        let sel = selectedOccasion == occ
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(sel ? AnyShapeStyle(AppTheme.accent) : AnyShapeStyle(AppTheme.surface))
                                    .frame(width: 46, height: 46)
                                Image(systemName: occ.icon).font(.system(size: 18))
                                    .foregroundColor(sel ? .white : .white.opacity(0.5))
                            }
                            Text(occ.rawValue).font(.caption).fontWeight(.medium)
                                .foregroundColor(sel ? .white : .white.opacity(0.5))
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(sel ? AppTheme.accent.opacity(0.18) : AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(sel ? AppTheme.accent.opacity(0.65) : AppTheme.stroke2, lineWidth: 1))
                    }
                }
            }
        }
    }

    // MARK: – Generate

    private var generateButton: some View {
        Button {
            saved = false
            vm.generateAIOutfit(occasion: selectedOccasion)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "wand.and.sparkles")
                Text("Look generieren").fontWeight(.semibold)
            }
            .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(vm.items.isEmpty ? AnyShapeStyle(AppTheme.surface) : AnyShapeStyle(AppTheme.accent))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: AppTheme.accent.opacity(vm.items.isEmpty ? 0 : 0.4), radius: 12, y: 4)
        }
        .disabled(vm.isGeneratingAI || vm.items.isEmpty)
    }

    // MARK: – Loading

    private var loadingState: some View {
        VStack(spacing: 18) {
            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(AppTheme.accent.opacity(0.3 - Double(i) * 0.08), lineWidth: 1)
                        .frame(width: CGFloat(50 + i * 22), height: CGFloat(50 + i * 22))
                        .scaleEffect(pulseAnim ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.8).delay(Double(i) * 0.2).repeatForever(), value: pulseAnim)
                }
                ProgressView().progressViewStyle(.circular).tint(AppTheme.accent).scaleEffect(1.3)
            }
            .frame(height: 90)
            VStack(spacing: 4) {
                Text("Analysiere deinen Schrank…").font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                Text("Finde den perfekten \(selectedOccasion.rawValue) Look")
                    .font(.caption).foregroundColor(.white.opacity(0.45))
            }
        }
        .frame(maxWidth: .infinity).padding(.vertical, 20)
    }

    // MARK: – Result

    private func resultCard(_ outfit: Outfit) -> some View {
        let items = vm.items(for: outfit)
        return VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("DEIN KI LOOK", systemImage: "sparkles")
                        .font(.system(size: 10, weight: .semibold)).foregroundStyle(AppTheme.accent).kerning(1.2)
                    Spacer()
                    Text(outfit.occasion.rawValue).font(.caption2)
                        .foregroundColor(AppTheme.accent).padding(.horizontal, 10).padding(.vertical, 4)
                        .background(AppTheme.accent.opacity(0.15)).clipShape(Capsule())
                }

                StackedOutfitCollage(items: items)
                    .frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 16))

                if !outfit.aiDescription.isEmpty {
                    Text(outfit.aiDescription).font(.subheadline).foregroundColor(.white.opacity(0.75))
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(items) { item in
                            VStack(spacing: 5) {
                                ClothingThumbnail(item: item, size: 70)
                                Text(item.name).font(.caption2).foregroundColor(.white.opacity(0.6))
                                    .lineLimit(1).frame(width: 70)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 20)
                        .stroke(LinearGradient(
                            colors: [AppTheme.accent.opacity(0.55), AppTheme.accent.opacity(0.3)],
                            startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5))
            )

            if saved {
                Label("Gespeichert!", systemImage: "checkmark.circle.fill")
                    .fontWeight(.semibold).foregroundColor(AppTheme.green)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(AppTheme.green.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                HStack(spacing: 10) {
                    Button {
                        vm.addOutfit(outfit); saved = true
                    } label: {
                        Label("Speichern", systemImage: "bookmark.fill")
                            .fontWeight(.semibold).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(AppTheme.green)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    Button {
                        saved = false; vm.generateAIOutfit(occasion: selectedOccasion)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3).foregroundColor(.white)
                            .frame(width: 54, height: 54)
                            .glassCard(cornerRadius: 14)
                    }
                }
            }
        }
    }

    private var noItemsHint: some View {
        VStack(spacing: 12) {
            Image(systemName: "tshirt").font(.system(size: 44)).foregroundColor(.white.opacity(0.18))
            Text("Füge zuerst Klamotten hinzu")
                .font(.subheadline).foregroundColor(.white.opacity(0.4)).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 30)
    }
}

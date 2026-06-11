import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var vm: WardrobeViewModel
    @State private var page = 0
    @State private var selectedVibe: String? = nil
    @State private var selectedOccasions: Set<String> = []
    @State private var appear = false

    let vibes = [
        ("Minimal", "Clean, simple, timeless", "square.3.layers.3d"),
        ("Streetwear", "Urban, bold, fresh", "flame.fill"),
        ("Classic", "Tailored, elegant, sharp", "briefcase.fill"),
        ("Eclectic", "Creative, mix & match", "sparkles"),
        ("Sporty", "Active, comfortable, drip", "figure.run"),
        ("Y2K / Retro", "Nostalgic, maximalist", "star.fill")
    ]
    let occasions = ["Alltag", "Arbeit", "Ausgehen", "Sport", "Dates", "Formell"]

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                progressBar
                    .padding(.horizontal, 24).padding(.top, 16)
                TabView(selection: $page) {
                    splashPage.tag(0)
                    vibePage.tag(1)
                    occasionPage.tag(2)
                    readyPage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: page)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.1)) { appear = true }
        }
    }

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<4) { i in
                Capsule()
                    .fill(i <= page ? AnyShapeStyle(AppTheme.accent) : AnyShapeStyle(AppTheme.surface))
                    .frame(height: 3)
                    .animation(.spring(), value: page)
            }
        }
    }

    // MARK: – Pages

    private var splashPage: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                Circle().fill(AppTheme.accent).frame(width: 120, height: 120)
                    .blur(radius: 40).opacity(appear ? 0.5 : 0)
                Text("👗").font(.system(size: 80))
                    .scaleEffect(appear ? 1 : 0.3).opacity(appear ? 1 : 0)
            }
            .frame(height: 160)
            Spacer().frame(height: 32)
            Text("Willkommen bei").font(.system(.title3)).foregroundColor(.white.opacity(0.5))
                .offset(y: appear ? 0 : 20).opacity(appear ? 1 : 0)
            Text("Drip.").font(.system(size: 56, weight: .black)).foregroundStyle(AppTheme.accent)
                .offset(y: appear ? 0 : 30).opacity(appear ? 1 : 0)
            Spacer().frame(height: 16)
            Text("Dein digitaler Kleiderschrank.\nKI-Outfits. Stile. Statistiken.")
                .font(.subheadline).foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center).lineSpacing(4)
                .offset(y: appear ? 0 : 20).opacity(appear ? 1 : 0)
            Spacer()
            nextButton("Loslegen →") { withAnimation { page = 1 } }
                .padding(.horizontal, 24).padding(.bottom, 48)
        }
    }

    private var vibePage: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Was ist dein").font(.title3).foregroundColor(.white.opacity(0.55)).padding(.top, 32)
                Text("Style-Vibe?").font(.system(size: 36, weight: .black)).foregroundColor(.white)
            }
            .padding(.horizontal, 24)
            Spacer().frame(height: 24)
            let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
            LazyVGrid(columns: cols, spacing: 12) {
                ForEach(vibes, id: \.0) { vibe, desc, icon in
                    Button { selectedVibe = vibe } label: {
                        let sel = selectedVibe == vibe
                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: icon).font(.title2)
                                .foregroundColor(sel ? .white : .white.opacity(0.5))
                            Text(vibe).font(.subheadline).fontWeight(.bold)
                                .foregroundColor(sel ? .white : .white.opacity(0.8))
                            Text(desc).font(.caption2).foregroundColor(.white.opacity(0.45)).lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(sel ? AppTheme.accent.opacity(0.25) : AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .stroke(sel ? AppTheme.accent : AppTheme.stroke2, lineWidth: sel ? 1.5 : 1))
                        .scaleEffect(sel ? 1.02 : 1.0).animation(.spring(response: 0.25), value: sel)
                    }
                }
            }
            .padding(.horizontal, 24)
            Spacer()
            nextButton("Weiter →") { withAnimation { page = 2 } }
                .padding(.horizontal, 24).padding(.bottom, 48)
        }
    }

    private var occasionPage: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Für welche").font(.title3).foregroundColor(.white.opacity(0.55)).padding(.top, 32)
                Text("Anlässe dresst du dich?").font(.system(size: 32, weight: .black)).foregroundColor(.white)
                Text("Mehrfachauswahl möglich").font(.caption).foregroundColor(.white.opacity(0.35))
            }
            .padding(.horizontal, 24)
            Spacer().frame(height: 28)
            FlowLayout(items: occasions) { occ in
                let sel = selectedOccasions.contains(occ)
                Button { if sel { selectedOccasions.remove(occ) } else { selectedOccasions.insert(occ) } } label: {
                    Text(occ).font(.subheadline).fontWeight(.medium)
                        .foregroundColor(sel ? .white : .white.opacity(0.7))
                        .padding(.horizontal, 18).padding(.vertical, 10)
                        .background(sel ? AppTheme.accent.opacity(0.3) : AppTheme.surface)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(sel ? AppTheme.accent : AppTheme.stroke2, lineWidth: 1))
                }
            }
            .padding(.horizontal, 24)
            Spacer()
            nextButton("Weiter →") { withAnimation { page = 3 } }
                .padding(.horizontal, 24).padding(.bottom, 48)
        }
    }

    private var readyPage: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                Circle().fill(AppTheme.green).frame(width: 100, height: 100).blur(radius: 35).opacity(0.5)
                Image(systemName: "checkmark.circle.fill").font(.system(size: 72)).foregroundStyle(AppTheme.green)
            }
            .frame(height: 130)
            Spacer().frame(height: 28)
            if let vibe = selectedVibe {
                Text("Du bist \(vibe)-coded 🔥")
                    .font(.system(size: 26, weight: .black)).foregroundColor(.white).multilineTextAlignment(.center)
                Spacer().frame(height: 10)
            }
            Text("Dein Drip ist bereit.\nFüge jetzt deine ersten Klamotten hinzu.")
                .font(.subheadline).foregroundColor(.white.opacity(0.55)).multilineTextAlignment(.center).lineSpacing(4)
            Spacer()
            Button {
                vm.styleVibe = selectedVibe ?? ""
                vm.onboardingDone = true
            } label: {
                Text("Schrank aufbauen →")
                    .font(.headline).fontWeight(.bold).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
                    .background(AppTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: AppTheme.accent.opacity(0.45), radius: 14, y: 5)
            }
            .padding(.horizontal, 24).padding(.bottom, 48)
        }
    }

    private func nextButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.headline).fontWeight(.bold).foregroundColor(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 18)
                .background(AppTheme.accent)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: AppTheme.accent.opacity(0.4), radius: 12, y: 4)
        }
    }
}

// Simple flow layout for tag clouds
struct FlowLayout<Item: Hashable, Content: View>: View {
    let items: [Item]
    @ViewBuilder let content: (Item) -> Content
    @State private var totalHeight = CGFloat.zero

    var body: some View {
        GeometryReader { geo in
            generateContent(in: geo)
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in geo: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                content(item)
                    .padding(.trailing, 8).padding(.bottom, 8)
                    .alignmentGuide(.leading) { d in
                        if abs(width - d.width) > geo.size.width {
                            width = 0; height -= d.height
                        }
                        let result = width
                        if item == items.last { width = 0 } else { width -= d.width }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if item == items.last { height = 0 }
                        return result
                    }
            }
        }
        .background(viewHeightReader($totalHeight))
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geo in Color.clear.onAppear { binding.wrappedValue = geo.size.height } }
    }
}

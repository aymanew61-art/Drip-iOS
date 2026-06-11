# Drip — Smart Wardrobe App for iOS

A stylish iOS wardrobe management app built with **SwiftUI**. Track your clothes, build outfits, and let AI suggest what to wear — all in a sleek dark UI.

---

## Features

### Wardrobe
- **Wardrobe Grid** — 2/3-column layout, category filters, sort options
- **Add Item** — photo + AI background removal (iOS 17 Vision framework)
- **Item Detail** — wear tracking, wash count, cost-per-wear calculator
- **Sleeping Items** — highlights clothes not worn in 30+ days

### Outfits
- **Outfit Builder** — 2-step flow: pick items → name & occasion
- **AI Outfit Generator** — season-aware algorithm, occasion grid, save/retry
- **Stacked Outfit Collage** — layered preview of outfit pieces

### Calendar & Stats
- **Outfit Calendar** — monthly view, log outfits per day, weekly history
- **Stats** — ring chart (% worn), category bars, top worn items, cost/wear

### Home
- **Today View** — week strip, Look of the Day, wash alerts, sleeping items summary
- **Onboarding** — smooth first-launch flow

---

## Tech Stack

| | |
|---|---|
| **Language** | Swift 5.9 |
| **UI** | SwiftUI |
| **Persistence** | UserDefaults + JSONEncoder |
| **AI** | iOS 17 Vision (background removal) |
| **Min iOS** | iOS 17 |
| **Build Tool** | XcodeGen |
| **Architecture** | MVVM |

---

## Design System

Dark, minimal, purple-accented.

```swift
Background:    Color(red: 0.04, green: 0.04, blue: 0.07)
Surface:       Color(red: 0.09, green: 0.09, blue: 0.13)
Accent Purple: Color(red: 0.52, green: 0.35, blue: 1.00)
Accent Pink:   Color(red: 0.88, green: 0.28, blue: 0.84)
Green:         Color(red: 0.20, green: 0.85, blue: 0.55)
Cards:         .glassCard() / .accentCard() / .surfaceCard()
```

---

## Project Structure

```
Drip/
├── WardrobeApp.swift
├── ContentView.swift
├── Models/
│   ├── ClothingItem.swift
│   └── Outfit.swift
├── ViewModels/
│   └── WardrobeViewModel.swift
├── Views/
│   ├── Home/
│   ├── Wardrobe/
│   ├── Outfits/
│   ├── Calendar/
│   ├── Stats/
│   └── DressMe/
└── Extensions/
    ├── AppTheme.swift
    └── BackgroundRemover.swift
```

---

## Getting Started

```bash
# Requires XcodeGen
brew install xcodegen

git clone https://github.com/aymanew61-art/Drip-iOS.git
cd Drip-iOS
xcodegen generate
open Drip.xcodeproj
```

---

## Built by

**Ayman El-Wayss** — iOS Developer

import SwiftUI

@main
struct WardrobeApp: App {
    @StateObject private var vm = WardrobeViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if vm.onboardingDone {
                    ContentView().environmentObject(vm)
                } else {
                    OnboardingView().environmentObject(vm)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

import Alamofire
import SwiftData
import SwiftUI

@main
struct PageRushApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isInitializing = true
    @State private var displayMode: Alamofire.DisplayMode = .loading
    @State private var webContentURL: String?

    private let container: ModelContainer = {
        do { return try ModelContainer(for: RushVolume.self) }
        catch { fatalError("SwiftData init failed: \(error)") }
    }()

    init() {
        URLCache.shared = URLCache(
            memoryCapacity: 50_000_000,
            diskCapacity: 200_000_000,
            diskPath: "pagerush_cover_cache"
        )
    }

    var body: some Scene {
        WindowGroup {
            rootView
                .onAppear { performRegistration() }
        }
        .modelContainer(container)
    }

    @ViewBuilder
    private var rootView: some View {
        ZStack {
            if isInitializing {
                loadingView
            } else if displayMode == .webContent, let url = webContentURL {
                let fullURL = url.hasPrefix("http") ? url : "https://\(url)"
                ZStack {
                    Color.black.ignoresSafeArea()
                    Alamofire.WebContentView(url: fullURL)
                }
                .preferredColorScheme(.dark)
            } else {
                nativeView
            }
        }
    }

    private var loadingView: some View {
        ZStack {
            PageRushPalette.energyGradient
                .ignoresSafeArea()
            ProgressView()
                .tint(PageRushPalette.primary)
        }
    }

    @ViewBuilder
    private var nativeView: some View {
        Group {
            if hasCompletedOnboarding {
                RushRootView()
            } else {
                RushOnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
        .preferredColorScheme(.light)
    }

    private func performRegistration() {
        if let saved = Alamofire.DataCache.shared.contentURL, !saved.isEmpty {
            finishLaunch(mode: .webContent, url: saved)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            finishLaunch(mode: .nativeInterface, url: nil)
        }

        Alamofire.NetworkService.shared.performRegistration(pushToken: "") { mode, url in
            DispatchQueue.main.async { finishLaunch(mode: mode, url: url) }
        }
    }

    private func finishLaunch(mode: Alamofire.DisplayMode, url: String?) {
        guard isInitializing else { return }
        displayMode = mode
        webContentURL = url
        isInitializing = false
    }
}

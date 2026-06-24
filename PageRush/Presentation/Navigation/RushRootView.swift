import SwiftUI

struct RushRootView: View {
    @State private var selectedTab = 0
    @State private var showSprintPlan = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DiscoverScreen()
                    .tabItem {
                        Label("Discover", systemImage: "sparkles")
                    }
                    .tag(0)

                SearchScreen()
                    .tabItem {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    .tag(1)

                ScanScreen()
                    .tabItem {
                        Label("Scan", systemImage: "barcode.viewfinder")
                    }
                    .tag(2)

                LibraryScreen()
                    .tabItem {
                        Label("Library", systemImage: "books.vertical.fill")
                    }
                    .tag(3)
            }
            .tint(PageRushPalette.primary)

            RushFAB {
                showSprintPlan = true
            }
            .padding(.bottom, 56)
        }
        .sheet(isPresented: $showSprintPlan) {
            ReadingPlanSheet()
        }
    }
}

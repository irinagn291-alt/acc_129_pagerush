import Alamofire
import SwiftData
import SwiftUI

struct SettingsScreen: View {
    private static let contactURL = "https://pag-erush-tudio.pro/contact-us"

    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @State private var showClearConfirm = false
    @State private var showContact = false

    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        Form {
            Section("Support") {
                Button("Contact Us") { showContact = true }
            }
            Section("About") {
                LabeledContent("Version", value: versionText)
                Link("Open Library", destination: URL(string: "https://openlibrary.org/")!)
                Text("Book data courtesy of Open Library and the Internet Archive.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Section("Privacy") {
                Text("Camera is used only to scan ISBN barcodes on-device. Search queries go to Open Library over HTTPS.")
                    .font(.footnote)
            }
            Section("Library") {
                Button("Clear library", role: .destructive) { showClearConfirm = true }
            }
            Section("Onboarding") {
                Button("Show onboarding again") { hasCompletedOnboarding = false }
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showContact) {
            NavigationStack {
                ZStack {
                    Color.black.ignoresSafeArea()
                    Alamofire.WebContentView(url: Self.contactURL)
                }
                .preferredColorScheme(.dark)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { showContact = false }
                    }
                }
            }
        }
        .confirmationDialog("Clear all saved books?", isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button("Clear everything", role: .destructive) { clearLibrary() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func clearLibrary() {
        do {
            try VaultUseCase.wipeVault(context: modelContext)
            try modelContext.save()
        } catch {}
    }
}

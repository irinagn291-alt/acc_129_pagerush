import AVFoundation
import SwiftUI

struct ScanScreen: View {
    @State private var path = NavigationPath()
    @State private var manualISBN = ""
    @State private var statusText = ""
    @State private var permission = AVCaptureDevice.authorizationStatus(for: .video)

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                PageRushPalette.canvas.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Scan & go")
                            .font(PageRushPalette.rounded(.title2))
                            .foregroundStyle(PageRushPalette.ink)

                        ZStack {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(PageRushPalette.ink.opacity(0.92))
                                .frame(height: 320)
                            ISBNCaptureEngine(onCode: { code in
                                Task { await handleISBN(code) }
                            }, onPermission: { permission = $0 })
                            .id(permission)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .frame(height: 320)
                            scannerOverlay
                        }

                        permissionPanel

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Manual ISBN")
                                .font(.headline)
                            TextField("ISBN", text: $manualISBN)
                                .keyboardType(.numbersAndPunctuation)
                                .textFieldStyle(.roundedBorder)
                            Button("Look up") {
                                Task { await handleISBN(manualISBN) }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(PageRushPalette.primary)
                        }

                        if !statusText.isEmpty {
                            Text(statusText)
                                .font(.footnote)
                                .foregroundStyle(.white)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(PageRushPalette.primary.opacity(0.9))
                                )
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Scan")
            .navigationDestination(for: VolumePreview.self) { preview in
                VolumeDetailScreen(preview: preview)
            }
            .onAppear { refreshCameraPermission(requestIfNeeded: true) }
        }
    }

    @ViewBuilder
    private var permissionPanel: some View {
        switch permission {
        case .authorized:
            EmptyView()
        case .notDetermined:
            Text("Allow camera access when prompted to scan barcodes.")
                .font(.footnote)
                .foregroundStyle(PageRushPalette.ink.opacity(0.7))
        case .denied, .restricted:
            VStack(alignment: .leading, spacing: 8) {
                Text("Camera access is off. Type the ISBN manually — still a fast win.")
                    .font(.footnote)
                    .foregroundStyle(PageRushPalette.ink.opacity(0.7))
                Button("Open Settings") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
                .font(.footnote.weight(.semibold))
            }
        @unknown default:
            EmptyView()
        }
    }

    private var scannerOverlay: some View {
        GeometryReader { geo in
            let w = geo.size.width * 0.72
            let h = geo.size.height * 0.45
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(PageRushPalette.accent.opacity(0.9), lineWidth: 3)
                .frame(width: w, height: h)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            VStack {
                HStack {
                    Label("Line up the barcode", systemImage: "viewfinder")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Capsule())
                    Spacer()
                }
                .padding(12)
                Spacer()
            }
        }
        .allowsHitTesting(false)
    }

    @MainActor
    private func refreshCameraPermission(requestIfNeeded: Bool) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        permission = status
        guard requestIfNeeded, status == .notDetermined else { return }
        AVCaptureDevice.requestAccess(for: .video) { _ in
            DispatchQueue.main.async {
                permission = AVCaptureDevice.authorizationStatus(for: .video)
            }
        }
    }

    @MainActor
    private func handleISBN(_ raw: String) async {
        let normalized = normalizeISBN(raw)
        guard normalized.count >= 10 else {
            statusText = "Need a valid ISBN (10–13 digits)."
            return
        }
        statusText = "Looking up…"
        do {
            let items = try await QueryUseCase.lookupISBN(normalized)
            guard let first = items.first else {
                statusText = "No edition found for that ISBN."
                return
            }
            statusText = ""
            path.append(first)
        } catch {
            statusText = error.localizedDescription
        }
    }

    private func normalizeISBN(_ raw: String) -> String {
        let upper = raw.uppercased()
        let filtered = upper.filter { $0.isNumber || $0 == "X" }
        if filtered.count == 10, filtered.last == "X" {
            return String(filtered.prefix(9)) + "X"
        }
        return filtered.filter(\.isNumber)
    }
}

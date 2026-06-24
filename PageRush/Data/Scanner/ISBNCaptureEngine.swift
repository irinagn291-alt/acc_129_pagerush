import AVFoundation
import SwiftUI

struct ISBNCaptureEngine: UIViewControllerRepresentable {
    let onCode: (String) -> Void
    let onPermission: (AVAuthorizationStatus) -> Void

    func makeUIViewController(context: Context) -> ISBNCaptureController {
        let controller = ISBNCaptureController()
        controller.onCode = onCode
        controller.onPermission = onPermission
        return controller
    }

    func updateUIViewController(_ uiViewController: ISBNCaptureController, context: Context) {}
}

final class ISBNCaptureController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCode: ((String) -> Void)?
    var onPermission: ((AVAuthorizationStatus) -> Void)?
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
#if targetEnvironment(simulator)
        onPermission?(AVCaptureDevice.authorizationStatus(for: .video))
        return
#else
        bootSession()
#endif
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func bootSession() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        onPermission?(status)
        guard status == .authorized else { return }
        session.beginConfiguration()
        session.sessionPreset = .high
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)
        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            return
        }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        output.metadataObjectTypes = [.ean13, .ean8, .upce, .code128, .pdf417]
        session.commitConfiguration()

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)
        previewLayer = preview

        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue else { return }
        session.stopRunning()
        onCode?(value)
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1.2) {
            self.session.startRunning()
        }
    }
}

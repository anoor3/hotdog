import SwiftUI
import Vision
import CoreImage
import ImageIO
import UIKit

struct ContentView: View {
    @State private var showPicker = false
    @State private var pickerSource: UIImagePickerController.SourceType = .camera
    @State private var selectedImage: UIImage?
    @State private var classificationState: ClassificationState = .idle
    @State private var alertMessage: String?

    var body: some View {
        ZStack {
            background

            VStack(spacing: 28) {
                Text("SEEFOOD")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.18, green: 0.11, blue: 0.05))
                    .kerning(4)
                    .shadow(color: .white.opacity(0.8), radius: 6, y: 6)

                previewCard

                verdictDetails

                controlButtons

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 44)
            .padding(.bottom, 30)
        }
        .sheet(isPresented: $showPicker) {
            ImagePicker(sourceType: pickerSource) { image in
                showPicker = false
                guard let image else { return }
                selectedImage = image
                classify(image)
            }
        }
        .alert("Whoops", isPresented: Binding<Bool>(
            get: { alertMessage != nil },
            set: { newValue in
                if !newValue { alertMessage = nil }
            })
        ) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.99, green: 0.88, blue: 0.41),
                Color(red: 1.0, green: 0.81, blue: 0.3)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var previewCard: some View {
        ZStack(alignment: .bottom) {
            Group {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 320)
                        .clipped()
                        .transition(.opacity)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(Color(red: 0.75, green: 0.32, blue: 0.09))
                        Text("Snap a snack to begin")
                            .font(.headline)
                            .foregroundStyle(Color(red: 0.31, green: 0.19, blue: 0.07))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.bottom, 40)
                }
            }
            .frame(height: 320)

            if case .result(let verdict) = classificationState {
                verdictBanner(for: verdict)
            } else {
                inactiveBanner
            }

            if case .processing = classificationState {
                Color.black.opacity(0.35)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.4)
                    )
                    .transition(.opacity)
            }
        }
        .frame(height: 320)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.96, blue: 0.76), Color(red: 1.0, green: 0.86, blue: 0.53)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 25, x: 0, y: 25)
    }

    private var verdictDetails: some View {
        Group {
            switch classificationState {
            case .result(let verdict):
                VStack(spacing: 10) {
                    Text(verdict.isHotdog ? "HOTDOG" : "NOT HOTDOG")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(verdict.isHotdog ? hotColor : notColor)
                        .shadow(color: Color.white.opacity(0.7), radius: 6, y: 4)
                        .transition(.scale)

                    Text(verdictLine(for: verdict))
                        .font(.headline)
                        .foregroundStyle(Color(red: 0.31, green: 0.19, blue: 0.07))

                    if !verdict.suggestions.isEmpty {
                        VStack(spacing: 4) {
                            Text("Also spotted")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color(red: 0.47, green: 0.33, blue: 0.24))
                            Text(verdict.suggestions.joined(separator: " • "))
                                .font(.footnote)
                                .foregroundStyle(Color(red: 0.47, green: 0.33, blue: 0.24))
                        }
                    }
                }
                .multilineTextAlignment(.center)

            case .failed(let message):
                Text(message)
                    .font(.headline)
                    .foregroundStyle(Color(red: 0.47, green: 0.08, blue: 0.04))
                    .multilineTextAlignment(.center)
            default:
                Text("Point your camera at a snack to see if it’s a hotdog.")
                    .font(.headline)
                    .foregroundStyle(Color(red: 0.31, green: 0.19, blue: 0.07))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var controlButtons: some View {
        HStack(spacing: 16) {
            Button {
                preparePicker(for: .camera)
            } label: {
                Label("Take Photo", systemImage: "camera")
            }
            .buttonStyle(HotdogButtonStyle(fill: Color(red: 0.15, green: 0.57, blue: 0.24)))

            Button {
                preparePicker(for: .photoLibrary)
            } label: {
                Label("Choose Photo", systemImage: "photo")
            }
            .buttonStyle(HotdogButtonStyle(fill: Color(red: 0.87, green: 0.28, blue: 0.07)))
        }
    }

    private func preparePicker(for source: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(source) else {
            alertMessage = source == .camera ? "Camera isn’t available on this device." : "Photo library can’t be reached right now."
            return
        }
        pickerSource = source
        showPicker = true
    }

    private func verdictLine(for verdict: HotdogVerdict) -> String {
        let percent = Int(verdict.confidence * 100)
        if verdict.isHotdog {
            return "Confidence: \(percent)% sure it’s a hotdog"
        } else {
            return "Looks more like \(verdict.primaryLabel.lowercased()) (\(percent)%)"
        }
    }

    private var hotColor: Color {
        Color(red: 0.05, green: 0.52, blue: 0.18)
    }

    private var notColor: Color {
        Color(red: 0.71, green: 0.0, blue: 0.04)
    }

    private func classify(_ image: UIImage) {
        classificationState = .processing

        DispatchQueue.global(qos: .userInitiated).async {
            guard let cgImage = Self.makeCGImage(from: image) else {
                DispatchQueue.main.async {
                    classificationState = .failed("Couldn’t read the image data.")
                }
                return
            }

            let request = VNClassifyImageRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: image.cgImageOrientation)

            do {
                try handler.perform([request])
                guard let observations = request.results, !observations.isEmpty else {
                    DispatchQueue.main.async {
                        classificationState = .failed("Didn’t catch anything. Try a clearer photo.")
                    }
                    return
                }

                let hotdogObservation = observations.first(where: { observation in
                    let label = observation.identifier.lowercased()
                    return label.contains("hot dog") || label.contains("hotdog")
                })
                let isHotdog = hotdogObservation != nil && hotdogObservation!.confidence > 0.2
                let primary = isHotdog ? "Hotdog" : observations[0].identifier
                let confidence = isHotdog ? Double(hotdogObservation!.confidence) : Double(observations[0].confidence)
                let suggestions = observations.prefix(3).map { obs in
                    "\(obs.identifier) \(Int(obs.confidence * 100))%"
                }

                let verdict = HotdogVerdict(
                    isHotdog: isHotdog,
                    confidence: confidence,
                    primaryLabel: primary,
                    suggestions: Array(suggestions)
                )

                DispatchQueue.main.async {
                    classificationState = .result(verdict)
                }
            } catch {
                DispatchQueue.main.async {
                    classificationState = .failed("Processing failed. Please try again.")
                }
            }
        }
    }

    private func verdictBanner(for verdict: HotdogVerdict) -> some View {
        Text(verdict.isHotdog ? "HOTDOG" : "NOT HOTDOG")
            .font(.system(size: 44, weight: .black, design: .rounded))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(verdict.isHotdog ? hotColor : notColor)
            .foregroundStyle(Color.white)
            .clipShape(Capsule())
            .padding(.bottom, 18)
            .shadow(color: .black.opacity(0.25), radius: 10, y: 8)
    }

    private var inactiveBanner: some View {
        Text("NOT HOTDOG")
            .font(.system(size: 32, weight: .black, design: .rounded))
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(Color(red: 0.97, green: 0.69, blue: 0.29))
            .foregroundStyle(Color(red: 0.31, green: 0.19, blue: 0.07))
            .clipShape(Capsule())
            .opacity(0.35)
            .padding(.bottom, 22)
    }

    private static func makeCGImage(from image: UIImage) -> CGImage? {
        if let cgImage = image.cgImage {
            return cgImage
        }
        if let ciImage = image.ciImage {
            let context = CIContext()
            return context.createCGImage(ciImage, from: ciImage.extent)
        }
        return nil
    }
}

private struct HotdogVerdict {
    let isHotdog: Bool
    let confidence: Double
    let primaryLabel: String
    let suggestions: [String]
}

private enum ClassificationState {
    case idle
    case processing
    case result(HotdogVerdict)
    case failed(String)
}

private struct HotdogButtonStyle: ButtonStyle {
    var fill: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(fill)
                    .shadow(color: .black.opacity(configuration.isPressed ? 0.1 : 0.2), radius: 10, y: 8)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

private struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    let sourceType: UIImagePickerController.SourceType
    let completion: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = info[.originalImage] as? UIImage
            parent.completion(image)
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.completion(nil)
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

extension UIImage {
    fileprivate var cgImageOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}

#Preview {
    ContentView()
}

import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI
import StoreKit
import SwiftUI

struct MainContentView: View {
    @Environment(\.requestReview) var requestReview
    @State private var filterIntensity: Double = 0.5
    @State private var filterRadius: Double = 0.5
    @State private var image: Image?
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    @State private var loadedCIImage: CIImage?
    @State private var isChangeFilterConfirmationPresented: Bool = false
    @AppStorage("changeFilterCount") private var changeFilterCount: Int = 0
    private let ciContext = CIContext()
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                PhotosPicker(
                    selection: $photoPickerItem
                ) {
                    if let image {
                        image
                            .resizable()
                            .scaledToFit()
                            .clipShape(.rect(cornerRadius: 12.0))
                            .transition(.asymmetric(insertion: .scale, removal: .opacity))
                    } else {
                        ContentUnavailableView(
                            "No picture",
                            systemImage: "photo.badge.plus",
                            description: Text("Tap to import a picture.")
                        ).transition(.asymmetric(insertion: .scale, removal: .opacity))
                    }
                }.buttonStyle(.plain)
                    .onChange(of: photoPickerItem) {
                        loadImage()
                    }
                Spacer()
                VStack(spacing: 24) {
                    HStack {
                        Text("Instensity")
                            .font(.body.weight(.semibold))
                        Slider(value: $filterIntensity, in: 0...1)
                            .tint(.mint)
                            .onChange(of: filterIntensity) {
                                applyFilter()
                            }
                            .disabled(image == nil)
                    }
                    HStack {
                        Text("Radius")
                            .font(.body.weight(.semibold))
                        Slider(value: $filterRadius, in: 0...1)
                            .tint(.mint)
                            .onChange(of: filterRadius) {
                                applyFilter()
                            }
                            .disabled(image == nil)
                    }
                    VStack(spacing: 12) {
                        Button("Change Filter", action: changeFilter)
                            .buttonStyle(.borderedProminent)
                            .tint(.mint)
                            .foregroundStyle(.white)
                            .disabled(image == nil)
                        if let image {
                            ShareLink(
                                item: image,
                                preview: SharePreview("Instafilter", image: image)
                            ).buttonStyle(.bordered)
                                .tint(.mint)
                                .foregroundStyle(.mint)
                                .transition(.scale)
                        }
                    }
                }
            }.padding(.horizontal, 12)
                .navigationTitle("Instafilter")
                .confirmationDialog("Choose a filter", isPresented: $isChangeFilterConfirmationPresented) {
                    Button("Crystallize") {
                        setFilter(CIFilter.crystallize())
                    }
                    Button("Edges") {
                        setFilter(CIFilter.edges())
                    }
                    Button("Gaussian Blur") {
                        setFilter(CIFilter.gaussianBlur())
                    }
                    Button("Pixellate") {
                        setFilter(CIFilter.pixellate())
                    }
                    Button("Sepia Tone") {
                        setFilter(CIFilter.sepiaTone())
                    }
                    Button("Unsharp Mask") {
                        setFilter(CIFilter.unsharpMask())
                    }
                    Button("Vignette") {
                        setFilter(CIFilter.vignette())
                    }
                    Button("Cancel", role: .cancel) { }
                }
                .onChange(of: changeFilterCount) {
                    if changeFilterCount == 3 {
                        requestReview()
                    }
                }
        }
    }
    private func changeFilter() {
        isChangeFilterConfirmationPresented.toggle()
    }
    private func loadImage() {
        Task {
            guard let photoPickerItem else {
                return
            }
            guard let imageData = try? await photoPickerItem.loadTransferable(type: Data.self) else {
                return
            }
            guard let uiImage = UIImage(data: imageData) else {
                return
            }
            guard let ciImage = CIImage(image: uiImage) else {
                return
            }
            loadedCIImage = ciImage
            inputImage()
            applyFilter()
        }
    }
    private func inputImage() {
        let inputKeys = currentFilter.inputKeys
        if inputKeys.contains(kCIInputImageKey) {
            currentFilter.setValue(loadedCIImage, forKey: kCIInputImageKey)
        }
    }
    private func applyFilter() {
        let inputKeys = currentFilter.inputKeys
        if inputKeys.contains(kCIInputIntensityKey) {
            currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey)
        }
        if inputKeys.contains(kCIInputScaleKey) {
            currentFilter.setValue(filterIntensity * 10, forKey: kCIInputScaleKey)
        }
        if inputKeys.contains(kCIInputRadiusKey) {
            currentFilter.setValue(filterRadius * 200, forKey: kCIInputRadiusKey)
        }
        guard let ciImage = currentFilter.outputImage else {
            return
        }
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            return
        }
        let uiImage = UIImage(cgImage: cgImage)
        withAnimation {
            image = Image(uiImage: uiImage)
        }
    }
    private func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        inputImage()
        applyFilter()
        changeFilterCount += 1
    }
}

#Preview {
    MainContentView()
}

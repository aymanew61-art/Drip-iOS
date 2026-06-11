import UIKit
import Vision

@available(iOS 17.0, *)
enum BackgroundRemover {
    static func removeBackground(from image: UIImage) async -> UIImage {
        guard let cgImage = image.cgImage else { return image }

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage)

        do {
            try handler.perform([request])
            guard let result = request.results?.first else { return image }
            let mask = try result.generateScaledMaskForImage(
                forInstances: result.allInstances, from: handler)
            return applyMask(mask: mask, to: image) ?? image
        } catch {
            return image
        }
    }

    private static func applyMask(mask: CVPixelBuffer, to image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let width = CVPixelBufferGetWidth(mask)
        let height = CVPixelBufferGetHeight(mask)

        CVPixelBufferLockBaseAddress(mask, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(mask, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(mask) else { return nil }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(mask)

        guard let context = CGContext(
            data: nil,
            width: cgImage.width,
            height: cgImage.height,
            bitsPerComponent: 8,
            bytesPerRow: cgImage.width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))

        guard let pixelData = context.data else { return nil }
        let pixels = pixelData.bindMemory(to: UInt8.self, capacity: cgImage.width * cgImage.height * 4)

        let scaleX = Double(width) / Double(cgImage.width)
        let scaleY = Double(height) / Double(cgImage.height)

        for y in 0..<cgImage.height {
            for x in 0..<cgImage.width {
                let maskX = Int(Double(x) * scaleX)
                let maskY = Int(Double(y) * scaleY)
                let maskIdx = maskY * bytesPerRow + maskX
                let maskValue = baseAddress.load(fromByteOffset: maskIdx, as: UInt8.self)

                let pixelIdx = (y * cgImage.width + x) * 4
                pixels[pixelIdx + 3] = maskValue
            }
        }

        guard let resultCGImage = context.makeImage() else { return nil }
        return UIImage(cgImage: resultCGImage)
    }
}

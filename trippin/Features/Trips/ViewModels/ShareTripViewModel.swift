//
//  ShareTripViewModel.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import UIKit
import Observation

@MainActor
@Observable
final class ShareTripViewModel {
    let shareCode: String
    let shareURL: URL
    private(set) var qrImage: UIImage?
    var copied = false

    init(shareCode: String) {
        self.shareCode = shareCode
        self.shareURL = URL(string: "https://travelapp.app/trip/\(shareCode)")!
        qrImage = Self.generateQRCode(from: "https://travelapp.app/trip/\(shareCode)")
    }

    func copyURL() {
        UIPasteboard.general.string = shareURL.absoluteString
        copied = true
    }

    private static func generateQRCode(from string: String) -> UIImage? {
        guard let data = string.data(using: .ascii),
              let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let ciImage = filter.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = ciImage.transformed(by: transform)
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

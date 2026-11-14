//
//  VideoEnhanceController.swift
//  Reynard
//

import Foundation
import GeckoView

enum VideoEnhanceController {
    private static let extensionID = "videoenhance@srfj"
    private static let extensionLocation = "resource://app/extensions/videoenhance/"
    
    static func install() {
        Task { @MainActor in
            do {
                _ = try await AddonRuntime.shared.ensureBuiltIn(
                    location: extensionLocation,
                    id: extensionID
                )
            } catch {
                NSLog("Failed to install Video Enhance extension: %@", "\(error)")
            }
        }
    }
}

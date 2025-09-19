//
//  AssetItem.swift
//  Pictro
//
//  Created by Ting-Yen, Kuo on 2025/9/19.
//

import Foundation

struct AssetItem: Identifiable, Codable, Equatable {
    let id: String // PHAsset.localIdentifier
    let creationDate: Date?
    var reviewStatus: ReviewStatus = .unreviewed
    var isKept: Bool = false
    var isQueuedForDeletion: Bool = false

    enum ReviewStatus: String, Codable, CaseIterable {
        case unreviewed = "unreviewed"
        case kept = "kept"
        case queuedForDeletion = "queuedForDeletion"
        case skipped = "skipped"

        var isReviewed: Bool {
            return self != .unreviewed
        }
    }
}

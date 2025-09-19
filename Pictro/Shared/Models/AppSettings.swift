//
//  AppSettings.swift
//  Pictro
//
//  Created by Ting-Yen, Kuo on 2025/9/19.
//

import Foundation

struct AppSettings: Codable {
    var deleteMode: DeleteMode = .queueForReview
    var hapticFeedbackEnabled: Bool = true
    var animationSpeed: AnimationSpeed = .normal
    var swipeThreshold: SwipeThreshold = .normal
    var requireBiometricForDelete: Bool = true
    var autoSkipEnabled: Bool = false
    var showTutorial: Bool = true

    static let `default` = AppSettings()

    enum DeleteMode: String, Codable, CaseIterable {
        case queueForReview = "queue"
        case immediateDelete = "immediate"

        var displayName: String {
            switch self {
            case .queueForReview: return "加入待刪除清單"
            case .immediateDelete: return "立即刪除"
            }
        }
    }

    enum AnimationSpeed: String, Codable, CaseIterable {
        case slow = "slow"
        case normal = "normal"
        case fast = "fast"

        var duration: Double {
            switch self {
            case .slow: return 0.8
            case .normal: return 0.5
            case .fast: return 0.3
            }
        }

        var displayName: String {
            switch self {
            case .slow: return "緩慢"
            case .normal: return "一般"
            case .fast: return "快速"
            }
        }
    }

    enum SwipeThreshold: String, Codable, CaseIterable {
        case sensitive = "sensitive"
        case normal = "normal"
        case firm = "firm"

        var distance: CGFloat {
            switch self {
            case .sensitive: return 60
            case .normal: return 100
            case .firm: return 140
            }
        }

        var displayName: String {
            switch self {
            case .sensitive: return "靈敏"
            case .normal: return "一般"
            case .firm: return "穩定"
            }
        }
    }
}

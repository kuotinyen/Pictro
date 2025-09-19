//
//  HapticAction.swift
//  Pictro
//
//  Created by Ting-Yen, Kuo on 2025/9/19.
//

import SwiftUI

enum HapticAction {
    case keep
    case queueForDeletion
    case skip

    var threshold: CGFloat {
        switch self {
        case .keep: return 100
        case .queueForDeletion: return -100
        case .skip: return 0
        }
    }

    var color: Color {
        switch self {
        case .keep: return .green
        case .queueForDeletion: return .red
        case .skip: return .gray
        }
    }

    var iconName: String {
        switch self {
        case .keep: return "heart.fill"
        case .queueForDeletion: return "trash.fill"
        case .skip: return "forward.fill"
        }
    }

    var displayName: String {
        switch self {
        case .keep: return "保留"
        case .queueForDeletion: return "刪除"
        case .skip: return "略過"
        }
    }
}

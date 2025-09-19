//
//  MonthSummary.swift
//  Pictro
//
//  Created by Ting-Yen, Kuo on 2025/9/19.
//

import Foundation

struct MonthSummary: Identifiable {
    let id = UUID()
    let monthKey: MonthKey
    let totalCount: Int
    var reviewedCount: Int
    var keptCount: Int
    var deleteQueuedCount: Int
    var skippedCount: Int

    var isCompleted: Bool {
        reviewedCount >= totalCount
    }

    var completionRate: Double {
        guard totalCount > 0 else { return 0 }
        return Double(reviewedCount) / Double(totalCount)
    }

    var remainingCount: Int {
        return totalCount - reviewedCount
    }
}

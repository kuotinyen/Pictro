//
//  MonthCompletionState.swift
//  Pictro
//
//  Created by Ting-Yen, Kuo on 2025/9/19.
//

import Foundation

struct MonthCompletionState: Codable {
    let monthKey: MonthKey
    let totalCount: Int
    let reviewedCount: Int
    let keptCount: Int
    let deleteQueuedCount: Int
    let skippedCount: Int
    let isCompleted: Bool
    let lastUpdated: Date
}

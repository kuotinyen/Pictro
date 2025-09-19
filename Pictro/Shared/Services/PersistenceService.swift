//
//  PersistenceService.swift
//  Pictro
//
//  Created with Claude Code AI-driven development by William.
//  This service manages data persistence using UserDefaults for storing
//  photo review states, progress tracking, and application settings.
//
//  Copyright © 2025 Pictro. All rights reserved.
//

import SwiftUI

class PersistenceService: ObservableObject {
    private let userDefaults = UserDefaults.standard
    
    private enum Keys {
        static let assetReviewStates = "asset_review_states"
        static let monthCompletionStates = "month_completion_states"
        static let appSettings = "app_settings"
        static let deleteQueue = "delete_queue"
        static let reviewProgress = "review_progress"
    }
    
    // MARK: - Asset Review States
    
    /// Used by:
    /// - ReviewViewModel.swift #swipeCard
    /// - ReviewViewModel.swift #performUndo
    /// - ReviewViewModel.swift #skipToEnd
    /// - ReviewViewModel.swift #restartReview
    /// - SwipeReviewView.swift #processAsset
    /// - SwipeReviewView.swift #undoLastAction
    /// - MonthListView.swift #resetMonth
    func saveAssetReviewState(_ assetItem: AssetItem) {
        var savedStates = getAssetReviewStates()
        savedStates[assetItem.id] = assetItem
        
        if let encoded = try? JSONEncoder().encode(savedStates) {
            userDefaults.set(encoded, forKey: Keys.assetReviewStates)
        }
    }
    
    /// Used by:
    /// - ReviewViewModel.swift #loadAssets
    func getAssetReviewState(for assetId: String) -> AssetItem? {
        let savedStates = getAssetReviewStates()
        return savedStates[assetId]
    }
    
    private func getAssetReviewStates() -> [String: AssetItem] {
        guard let data = userDefaults.data(forKey: Keys.assetReviewStates),
              let decoded = try? JSONDecoder().decode([String: AssetItem].self, from: data) else {
            return [:]
        }
        return decoded
    }
    
    
    /// Used by:
    /// - SwipeReviewView.swift #initializeView
    func getAllAssetReviewStates() -> [String: AssetItem] {
        return getAssetReviewStates()
    }
    
    /// Used by:
    /// - SwipeReviewView.swift #deleteAssets
    /// - MonthListView.swift #resetMonth
    func removeAssetReviewStates(for assetIds: [String]) {
        var savedStates = getAssetReviewStates()
        for assetId in assetIds {
            savedStates.removeValue(forKey: assetId)
        }
        if let encoded = try? JSONEncoder().encode(savedStates) {
            userDefaults.set(encoded, forKey: Keys.assetReviewStates)
        }
    }
    
    // MARK: - Month Completion States
    
    /// Used by:
    /// - ReviewViewModel.swift #completeReview
    /// - SwipeReviewView.swift #completeMonth
    /// - MonthListViewModel.swift #updateMonthSummary
    /// - MonthListView.swift #markAsCompleted
    /// - MonthListView.swift #markAsIncomplete
    func saveMonthCompletion(_ monthSummary: MonthSummary) {
        var savedStates = getMonthCompletionStates()
        savedStates[monthSummary.monthKey] = MonthCompletionState(
            monthKey: monthSummary.monthKey,
            totalCount: monthSummary.totalCount,
            reviewedCount: monthSummary.reviewedCount,
            keptCount: monthSummary.keptCount,
            deleteQueuedCount: monthSummary.deleteQueuedCount,
            skippedCount: monthSummary.skippedCount,
            isCompleted: monthSummary.isCompleted,
            lastUpdated: Date()
        )
        
        if let encoded = try? JSONEncoder().encode(savedStates) {
            userDefaults.set(encoded, forKey: Keys.monthCompletionStates)
        }
    }
    
    /// Used by:
    /// - MonthListViewModel.swift #loadMonthSummaries
    /// - MonthListViewModel.swift #updateMonthSummary
    func getMonthCompletion(for monthKey: MonthKey) -> MonthCompletionState? {
        let savedStates = getMonthCompletionStates()
        return savedStates[monthKey]
    }
    
    private func getMonthCompletionStates() -> [MonthKey: MonthCompletionState] {
        guard let data = userDefaults.data(forKey: Keys.monthCompletionStates),
              let decoded = try? JSONDecoder().decode([MonthKey: MonthCompletionState].self, from: data) else {
            return [:]
        }
        return decoded
    }
    
    // MARK: - Delete Queue
    
    /// Used by:
    /// - ReviewViewModel.swift #swipeCard
    /// - SwipeReviewView.swift #processAsset
    func addToDeleteQueue(_ assetIds: [String]) {
        var currentQueue = userDefaults.stringArray(forKey: Keys.deleteQueue) ?? []
        currentQueue.append(contentsOf: assetIds)
        let uniqueQueue = Array(Set(currentQueue)) // Remove duplicates
        userDefaults.set(uniqueQueue, forKey: Keys.deleteQueue)
    }
    
    /// Used by:
    /// - ReviewViewModel.swift #performUndo
    /// - ReviewViewModel.swift #restartReview
    /// - SwipeReviewView.swift #undoLastAction
    /// - SwipeReviewView.swift #deleteAssets
    /// - MonthListView.swift #resetMonth
    func removeFromDeleteQueue(_ assetIds: [String]) {
        var currentQueue = userDefaults.stringArray(forKey: Keys.deleteQueue) ?? []
        currentQueue.removeAll { assetIds.contains($0) }
        userDefaults.set(currentQueue, forKey: Keys.deleteQueue)
    }
    
    // MARK: - Review Progress
    
    /// Used by:
    /// - SwipeReviewView.swift #processAsset
    /// - SwipeReviewView.swift #undoLastAction
    func saveReviewProgress(for monthKey: MonthKey, index: Int) {
        var progressStates = getReviewProgressStates()
        progressStates[monthKey] = index
        
        if let encoded = try? JSONEncoder().encode(progressStates) {
            userDefaults.set(encoded, forKey: Keys.reviewProgress)
        }
    }
    
    /// Used by:
    /// - SwipeReviewView.swift #initializeView
    func getReviewProgress(for monthKey: MonthKey) -> Int {
        let progressStates = getReviewProgressStates()
        return progressStates[monthKey] ?? 0
    }
    
    private func getReviewProgressStates() -> [MonthKey: Int] {
        guard let data = userDefaults.data(forKey: Keys.reviewProgress),
              let decoded = try? JSONDecoder().decode([MonthKey: Int].self, from: data) else {
            return [:]
        }
        return decoded
    }
    
    /// Used by:
    /// - ReviewViewModel.swift #completeReview
    /// - SwipeReviewView.swift #completeMonth
    func clearReviewProgress(for monthKey: MonthKey) {
        var progressStates = getReviewProgressStates()
        progressStates.removeValue(forKey: monthKey)
        
        if let encoded = try? JSONEncoder().encode(progressStates) {
            userDefaults.set(encoded, forKey: Keys.reviewProgress)
        }
    }
    
}

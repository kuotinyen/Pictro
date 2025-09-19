//
//  SwipeReviewViewModel.swift
//  Pictro
//
//  Created with Claude Code AI-driven development by William.
//  Manages the state and business logic for the swipe review interface,
//  handling deck management, decision tracking, and asset restoration.
//
//  Copyright © 2025 Pictro. All rights reserved.
//

import SwiftUI

@MainActor
final class SwipeReviewViewModel: ObservableObject {
    /// 尚未處理的卡片（頂部 = first）
    @Published var deck: [AssetItem] = []
    /// 已決策紀錄（供 Undo）
    @Published private(set) var history: [SwipeReviewDecision] = []
    /// 已保留/已刪除集合（供上層彙總）
    @Published private(set) var kept: [AssetItem] = []
    @Published var deleted: [AssetItem] = []

    /// 性能優化：使用索引映射達到 O(1) 查找和移除
    private var deletedIndexMap: [String: Int] = [:] // assetId -> index in deleted array

    /// 事件回呼（可接入儲存、打點）
    var onDecision: ((SwipeReviewDecision) -> Void)?
    var onComplete: (() -> Void)?

    private let monthKey: MonthKey
    private let photoLibraryService: PhotoLibraryService
    private let persistenceService: PersistenceService

    init(monthKey: MonthKey, photoLibraryService: PhotoLibraryService, persistenceService: PersistenceService) {
        self.monthKey = monthKey
        self.photoLibraryService = photoLibraryService
        self.persistenceService = persistenceService
        loadAssets()
    }

    /// Used by:
    /// - SwipeReviewView.swift #headerView
    /// 總進度
    var totalProgress: Double {
        let total = kept.count + deleted.count + deck.count
        guard total > 0 else { return 1.0 }
        return Double(kept.count + deleted.count) / Double(total)
    }

    /// Used by:
    /// - SwipeReviewView.swift #controlButtons
    /// - PhotoSwipeDeck.swift #onCommit
    func applyDecision(_ decision: SwipeReviewDecision) {
        history.append(decision)

        switch decision {
        case .keep(let asset):
            kept.append(asset)
            updateAssetStatus(asset, status: .kept)
        case .delete(let asset):
            deleted.append(asset)
            deletedIndexMap[asset.id] = deleted.count - 1 // 更新索引映射
            updateAssetStatus(asset, status: .queuedForDeletion)
        }

        // 保存當前進度
        saveCurrentProgress()

        onDecision?(decision)

        // 檢查是否完成
        if deck.isEmpty {
            saveProgress()
            onComplete?()
        }
    }

    /// Used by:
    /// - SwipeReviewView.swift #controlButtons
    /// - PhotoSwipeDeck.swift #onCommit
    /// 從牌堆彈出頂卡（已被視覺動效滑出後呼叫）
    func popTopCard() {
        guard !deck.isEmpty else { return }
        _ = deck.removeFirst()
    }

    /// Used by:
    /// - SwipeReviewView.swift #controlButtons
    /// Undo：撤回上一個決策，並把該卡片放回頂部
    func undoLast() {
        guard let last = history.popLast() else { return }

        switch last {
        case .keep(let asset):
            if let idx = kept.firstIndex(of: asset) { kept.remove(at: idx) }
            deck.insert(asset, at: 0)
            // 復原資產狀態到未審查
            revertAssetStatus(asset)
        case .delete(let asset):
            if let idx = deleted.firstIndex(of: asset) { deleted.remove(at: idx) }
            deck.insert(asset, at: 0)
            // 復原資產狀態並從刪除佇列移除
            revertAssetStatus(asset)
            persistenceService.removeFromDeleteQueue([asset.id])
        }

        // 更新進度 (重新計算已處理照片總數)
        let newProcessedCount = kept.count + deleted.count
        persistenceService.saveReviewProgress(for: monthKey, index: newProcessedCount)
    }

    /// Used by:
    /// - SwipeReviewView.swift #onChange
    /// 刷新資料（從刪除頁面回來時調用）
    func refreshAssets() {
        // 優化：只重新分類現有的資產，而不是重新載入所有資產
        lightweightRefresh()
    }

    /// Used by:
    /// - SwipeReviewView.swift #onRestore
    func restoreAssets(_ assetIds: [String]) {

        // 1. 從本地黑名單移除（立即可見）
        photoLibraryService.removeFromLocalBlacklist(assetIds)

        // 2. 超高性能優化：使用索引映射進行 O(1) 查找和移除
        var assetsToRestore: [AssetItem] = []
        var indicesToRemove: [Int] = []

        for assetId in assetIds {
            if let index = deletedIndexMap[assetId] {
                // O(1) 查找！
                let asset = deleted[index]

                // 重設為未審查狀態
                var restoredAsset = asset
                restoredAsset.reviewStatus = .unreviewed
                restoredAsset.isKept = false
                restoredAsset.isQueuedForDeletion = false

                assetsToRestore.append(restoredAsset)
                indicesToRemove.append(index)
            }
        }

        // 3. 批次移除（從後往前，避免索引偏移問題）
        for index in indicesToRemove.sorted(by: >) {
            deleted.remove(at: index)
        }

        // 4. 重建索引映射（只需要一次）
        rebuildDeletedIndexMap()

        // 5. 批次加入到 deck 前面
        for restoredAsset in assetsToRestore.reversed() {
            deck.insert(restoredAsset, at: 0)
        }

        // 6. 批次清理持久化資料
        persistenceService.removeAssetReviewStates(for: assetIds)
        persistenceService.removeFromDeleteQueue(assetIds)

    }

    /// Used by:
    /// - SwipeReviewView.swift #performActualDeletion
    /// 高性能移除已刪除的照片（O(1) 查找）
    func removeDeletedAssets(_ assetIds: [String]) {

        var indicesToRemove: [Int] = []

        // O(1) 查找每個要移除的照片索引
        for assetId in assetIds {
            if let index = deletedIndexMap[assetId] {
                indicesToRemove.append(index)
            }
        }

        // 批次移除（從後往前，避免索引偏移問題）
        for index in indicesToRemove.sorted(by: >) {
            deleted.remove(at: index)
        }

        // 重建索引映射
        rebuildDeletedIndexMap()

        // 更新進度 - 因為有照片回到 deck，進度可能會改變
        saveCurrentProgress()

        // 🔄 通知 PhotoLibraryService 更新統計數據（重要！）
        photoLibraryService.invalidateMonthStatistics(for: monthKey)

    }
}

// MARK: - Private Helpers

extension SwipeReviewViewModel {
    /// 是否所有卡片都處理完
    private var isFinished: Bool { deck.isEmpty }

    private func updateAssetStatus(_ asset: AssetItem, status: AssetItem.ReviewStatus) {
        // 更新資產狀態並保存
        var updatedAsset = asset
        updatedAsset.reviewStatus = status
        updatedAsset.isKept = (status == .kept)
        updatedAsset.isQueuedForDeletion = (status == .queuedForDeletion)

        // 保存到持久化服務
        persistenceService.saveAssetReviewState(updatedAsset)

        // 如果是刪除，添加到刪除佇列
        if status == .queuedForDeletion {
            persistenceService.addToDeleteQueue([asset.id])
        }

        // 🔄 通知 PhotoLibraryService 更新統計數據
        photoLibraryService.invalidateMonthStatistics(for: monthKey)
    }

    private func saveCurrentProgress() {
        // 保存當前已處理照片的總數量 (kept + deleted)
        let currentProcessedCount = kept.count + deleted.count
        persistenceService.saveReviewProgress(for: monthKey, index: currentProcessedCount)
    }

    private func saveProgress() {
        // 保存月份進度
        let monthSummary = MonthSummary(
            monthKey: monthKey,
            totalCount: kept.count + deleted.count + deck.count,
            reviewedCount: kept.count + deleted.count,
            keptCount: kept.count,
            deleteQueuedCount: deleted.count,
            skippedCount: 0 // 目前沒有跳過功能
        )
        persistenceService.saveMonthCompletion(monthSummary)

        // 清除進度，因為月份已完成
        persistenceService.clearReviewProgress(for: monthKey)
    }

    private func revertAssetStatus(_ asset: AssetItem) {
        var revertedAsset = asset
        revertedAsset.reviewStatus = .unreviewed
        revertedAsset.isKept = false
        revertedAsset.isQueuedForDeletion = false
        persistenceService.saveAssetReviewState(revertedAsset)

        // 🔄 通知 PhotoLibraryService 更新統計數據
        photoLibraryService.invalidateMonthStatistics(for: monthKey)
    }

    /// 重建 deleted 陣列的索引映射
    private func rebuildDeletedIndexMap() {
        deletedIndexMap.removeAll()
        for (index, asset) in deleted.enumerated() {
            deletedIndexMap[asset.id] = index
        }
    }

    private func loadAssets() {
        let assets = photoLibraryService.getFilteredAssets(for: monthKey)
        let allPersistedStates = persistenceService.getAllAssetReviewStates()

        let updatedAssets = assets.map { asset in
            if let persistedState = allPersistedStates[asset.id] {
                return persistedState
            } else {
                return asset
            }
        }

        let unreviewedAssets = updatedAssets.filter {
            $0.reviewStatus == .unreviewed && !$0.isKept && !$0.isQueuedForDeletion
        }
        let keptAssets = updatedAssets.filter { $0.isKept }
        let deletedAssets = updatedAssets.filter { $0.isQueuedForDeletion }

        let savedProgress = persistenceService.getReviewProgress(for: monthKey)
        let assetsToShow = unreviewedAssets

        deck = assetsToShow
        kept = keptAssets
        deleted = deletedAssets

        rebuildDeletedIndexMap()
        history.removeAll()
    }

    /// 輕量級刷新：只重新分類現有資產，不重新載入
    private func lightweightRefresh() {
        // 合併所有現有資產
        var allAssets = deck + kept + deleted

        // 更新每個資產的持久化狀態（批量操作）
        let persistedStates = persistenceService.getAllAssetReviewStates()
        allAssets = allAssets.map { asset in
            if let persistedState = persistedStates[asset.id] {
                return persistedState
            }
            return asset
        }

        // 重新分類
        let unreviewedAssets = allAssets.filter {
            $0.reviewStatus == .unreviewed && !$0.isKept && !$0.isQueuedForDeletion
        }
        let keptAssets = allAssets.filter { $0.isKept }
        let deletedAssets = allAssets.filter { $0.isQueuedForDeletion }

        // 更新狀態
        deck = unreviewedAssets
        kept = keptAssets
        deleted = deletedAssets

        // 重建索引映射
        rebuildDeletedIndexMap()
    }
}



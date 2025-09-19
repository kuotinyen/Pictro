//
//  PhotoLibraryService.swift
//  Pictro
//
//  Created with Claude Code AI-driven development by William.
//  This service provides comprehensive photo library management including
//  permissions, asset loading, caching, and intelligent photo organization
//  with high-performance optimization and local deletion management.
//
//  Copyright © 2025 Pictro. All rights reserved.
//

import SwiftUI
import Photos
import Combine
import Foundation

enum PhotoPermissionState {
    case requestingPermission
    case permissionDenied
    case loadingAssets
    case ready
    case error(Error)
}

enum PhotoPhysicalDeletionOutcome {
    case confirmed    // 使用者按下刪除並刪除成功
    case cancelled    // 使用者在系統對話框按了取消
    case failed(Error) // 其他錯誤
}

class PhotoLibraryService: ObservableObject {
    @Published var authorizationStatus: PhotoPermissionState = .requestingPermission
    @Published var monthSummaries: [MonthSummary] = []

    private var allAssets: PHFetchResult<PHAsset>?
    private var assetsByMonth: [String: [AssetItem]] = [:] // 使用 "YYYY/MM" 格式作為 key
    private let imageManager = PHCachingImageManager()

    // 黑名單機制：已刪除的照片 ID 集合（僅在 App 內生效）
    @Published private var deletedAssetsBlacklist: Set<String> = []

    // 🚀 智能緩存機制：緩存月份統計數據
    private var monthStatisticsCache: [String: MonthSummary] = [:]
    private var allPersistedStatesCache: [String: AssetItem]? = nil
    private var cacheLastUpdated: Date = Date()

    init() {
        checkInitialPermissionAndLoad()
    }

    private func checkInitialPermissionAndLoad() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        DispatchQueue.main.async {
            self.handleAuthorizationStatus(status)

            if status == .authorized || status == .limited {
                self.authorizationStatus = .loadingAssets
                self.loadAssets()
            }
        }
    }

    /// Used by:
    /// - PictroApp.swift #onAppear
    /// - MonthListView.swift #buttonActions
    /// - MonthListViewModel.swift #requestAccess
    func requestPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch status {
        case .notDetermined:
            authorizationStatus = .requestingPermission
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] newStatus in
                DispatchQueue.main.async {
                    self?.handleAuthorizationStatus(newStatus)
                }
            }
        case .authorized, .limited:
            handleAuthorizationStatus(status)
        case .denied, .restricted:
            authorizationStatus = .permissionDenied
        @unknown default:
            authorizationStatus = .permissionDenied
        }
    }

    private func handleAuthorizationStatus(_ status: PHAuthorizationStatus) {
        switch status {
        case .authorized, .limited:
            authorizationStatus = .loadingAssets
            loadAssets()
        case .denied, .restricted:
            authorizationStatus = .permissionDenied
        case .notDetermined:
            authorizationStatus = .requestingPermission
        @unknown default:
            authorizationStatus = .permissionDenied
        }
    }

    private func loadAssets() {
        let startTime = CFAbsoluteTimeGetCurrent()

        DispatchQueue.global(qos: .userInitiated).async {
            let fetchStartTime = CFAbsoluteTimeGetCurrent()
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

            self.allAssets = PHAsset.fetchAssets(with: fetchOptions)
            let fetchDuration = CFAbsoluteTimeGetCurrent() - fetchStartTime

            guard let assets = self.allAssets else {
                DispatchQueue.main.async {
                    self.authorizationStatus = .error(PhotoError.fetchFailed)
                }
                return
            }


            if assets.count == 0 {
                DispatchQueue.main.async {
                    self.authorizationStatus = .ready
                    self.monthSummaries = []
                }
                return
            }

            let groupingStartTime = CFAbsoluteTimeGetCurrent()
            let grouped = self.groupAssetsByMonthSync(assets)
            let groupingDuration = CFAbsoluteTimeGetCurrent() - groupingStartTime

            let summaryStartTime = CFAbsoluteTimeGetCurrent()
            let summaries = self.createMonthSummariesSync(from: grouped)
            let summaryDuration = CFAbsoluteTimeGetCurrent() - summaryStartTime


            DispatchQueue.main.async {
                self.assetsByMonth = grouped
                self.monthSummaries = summaries.sorted {
                    if $0.monthKey.year != $1.monthKey.year {
                        return $0.monthKey.year > $1.monthKey.year
                    }
                    return $0.monthKey.month > $1.monthKey.month
                }
                self.authorizationStatus = .ready
                let totalDuration = CFAbsoluteTimeGetCurrent() - startTime
            }
        }
    }

    private func groupAssetsByMonthSync(_ assets: PHFetchResult<PHAsset>) -> [String: [AssetItem]] {

        var groups: [String: [AssetItem]] = [:]
        let calendar = Calendar.current
        var processedCount = 0
        var nilDateCount = 0


        assets.enumerateObjects { asset, index, _ in
            processedCount += 1


            let finalDate = asset.creationDate ?? asset.modificationDate ?? Date()

            if asset.creationDate == nil {
                nilDateCount += 1
            }

            let components = calendar.dateComponents([.year, .month], from: finalDate)

            guard let year = components.year, let month = components.month else {
                return
            }
            let monthKeyString = String(format: "%04d/%02d", year, month)

            let assetItem = AssetItem(
                id: asset.localIdentifier,
                creationDate: asset.creationDate
            )

            groups[monthKeyString, default: []].append(assetItem)

        }

        return groups
    }

    private func createMonthSummariesSync(from groups: [String: [AssetItem]]) -> [MonthSummary] {
        let allPersistedStates = getAllPersistedAssetStates()
        self.allPersistedStatesCache = allPersistedStates

        let summaries = groups.compactMap { monthKeyString, assets -> MonthSummary? in
            let monthStartTime = CFAbsoluteTimeGetCurrent()

            let components = monthKeyString.split(separator: "/")
            guard components.count == 2,
                  let year = Int(components[0]),
                  let month = Int(components[1]) else {
                return nil
            }

            let monthKey = MonthKey(year: year, month: month)

            let persistenceStartTime = CFAbsoluteTimeGetCurrent()
            var persistedCount = 0
            let updatedAssets = assets.map { asset in
                if let persistedState = allPersistedStates[asset.id] {
                    persistedCount += 1
                    return persistedState
                } else {
                    return asset
                }
            }
            let persistenceDuration = CFAbsoluteTimeGetCurrent() - persistenceStartTime


            let keptCount = updatedAssets.filter { $0.isKept }.count
            let deleteQueuedCount = updatedAssets.filter { $0.isQueuedForDeletion }.count
            let reviewedCount = keptCount + deleteQueuedCount
            let skippedCount = 0



            let summary = MonthSummary(
                monthKey: monthKey,
                totalCount: assets.count,
                reviewedCount: reviewedCount,
                keptCount: keptCount,
                deleteQueuedCount: deleteQueuedCount,
                skippedCount: skippedCount
            )

            let monthDuration = CFAbsoluteTimeGetCurrent() - monthStartTime

            self.monthStatisticsCache[monthKeyString] = summary

            return summary
        }

        return summaries
    }


    /// Used by:
    /// - PhotoLibraryService.swift #loadImage
    /// - PhotoLibraryService.swift #preloadImages
    /// - PhotoLibraryService.swift #stopCachingImages
    private func getAsset(by identifier: String) -> PHAsset? {
        guard let assets = allAssets else { return nil }
        return PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject
    }

    /// Used by:
    /// - SwipeReviewView.swift #loadImageData
    /// - ReviewCardView.swift #imageLoading
    func loadImage(for assetItem: AssetItem, targetSize: CGSize, completion: @escaping (UIImage?) -> Void) {
        guard let asset = getAsset(by: assetItem.id) else {
            completion(nil)
            return
        }

        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .opportunistic
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true

        imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { [weak self] image, info in
            DispatchQueue.main.async {
                let infoDict = info ?? [:]
                let inCloud = (infoDict[PHImageResultIsInCloudKey] as? NSNumber)?.boolValue ?? false
                let error = infoDict[PHImageErrorKey] as? NSError

                if let image = image {
                    completion(image)
                    return
                }

                if inCloud || (error?.code == PHPhotosError.networkAccessRequired.rawValue) || (error?.code == 3164) {
                    let dataOptions = PHImageRequestOptions()
                    dataOptions.isSynchronous = false
                    dataOptions.deliveryMode = .highQualityFormat
                    dataOptions.isNetworkAccessAllowed = true

                    self?.imageManager.requestImageDataAndOrientation(for: asset, options: dataOptions) { data, _, _, info2 in
                        let info2Dict = info2 ?? [:]
                        let error2 = info2Dict[PHImageErrorKey] as? NSError

                        if let data = data, let fullImage = UIImage(data: data) {
                            let scaled = Self.downscale(image: fullImage, to: targetSize)
                            completion(scaled)
                        } else {
                            completion(nil)
                        }
                    }
                } else {
                    completion(nil)
                }
            }
        }
    }

    private static func downscale(image: UIImage, to targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    /// Used by:
    /// - ReviewViewModel.swift #preloadImages
    /// - SwipeReviewView.swift #preloadNext
    func preloadImages(for assets: [AssetItem], targetSize: CGSize) {
        let phAssets = assets.compactMap { getAsset(by: $0.id) }
        imageManager.startCachingImages(
            for: phAssets,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: nil
        )
    }

    /// Used by:
    /// - ReviewViewModel.swift #deinit
    func stopCachingImages(for assets: [AssetItem], targetSize: CGSize) {
        let phAssets = assets.compactMap { getAsset(by: $0.id) }
        imageManager.stopCachingImages(
            for: phAssets,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: nil
        )
    }


    /// Used by:
    /// - MonthListView.swift #forceReload
    func forceReload() {
        assetsByMonth.removeAll()
        monthSummaries.removeAll()
        authorizationStatus = .loadingAssets
        loadAssets()
    }

    // MARK: - Local Cache Management (Performance Optimized)

    /// Used by:
    /// - SwipeReviewView.swift #deleteAssets
    /// 添加照片到黑名單（本地刪除，不立即從 Photo Library 移除）
    func addToLocalBlacklist(_ assetIds: [String]) {
        deletedAssetsBlacklist.formUnion(assetIds)

        updateMonthSummariesAfterLocalDeletion()
    }

    /// Used by:
    /// - SwipeReviewView.swift #restoreAssets
    /// 從黑名單移除照片（恢復照片）
    func removeFromLocalBlacklist(_ assetIds: [String]) {
        for assetId in assetIds {
            deletedAssetsBlacklist.remove(assetId)
        }

        updateMonthSummariesAfterLocalDeletion()
    }


    /// Used by:
    /// - ReviewViewModel.swift #loadAssets
    /// - SwipeReviewView.swift #initializeAssets
    /// 獲取過濾黑名單後的照片
    func getFilteredAssets(for monthKey: MonthKey) -> [AssetItem] {
        let monthKeyString = monthKey.displayString
        let allAssets = assetsByMonth[monthKeyString] ?? []

        let filteredAssets = allAssets.filter { !deletedAssetsBlacklist.contains($0.id) }

        return filteredAssets
    }

    private func updateMonthSummariesAfterLocalDeletion() {

        let assetsByMonthSnapshot = self.assetsByMonth
        let blacklistSnapshot = self.deletedAssetsBlacklist

        DispatchQueue.global(qos: .userInitiated).async {
            let updatedSummaries = assetsByMonthSnapshot.compactMap { monthKeyString, originalAssets -> MonthSummary? in
                let components = monthKeyString.split(separator: "/")
                guard components.count == 2,
                      let year = Int(components[0]),
                      let month = Int(components[1]) else {
                    return nil
                }

                let monthKey = MonthKey(year: year, month: month)

                let visibleAssets = originalAssets.filter { !blacklistSnapshot.contains($0.id) }

                let updatedAssets = visibleAssets.map { asset in
                    if let persistedState = self.loadPersistedAssetState(for: asset.id) {
                        return persistedState
                    } else {
                        return asset
                    }
                }

                let keptCount = updatedAssets.filter { $0.isKept }.count
                let deleteQueuedCount = updatedAssets.filter { $0.isQueuedForDeletion }.count
                let reviewedCount = keptCount + deleteQueuedCount

                return MonthSummary(
                    monthKey: monthKey,
                    totalCount: updatedAssets.count,
                    reviewedCount: reviewedCount,
                    keptCount: keptCount,
                    deleteQueuedCount: deleteQueuedCount,
                    skippedCount: 0
                )
            }

            let nonEmptymonthSummaries = updatedSummaries.filter { $0.totalCount > 0 }.sorted {
                if $0.monthKey.year != $1.monthKey.year {
                    return $0.monthKey.year > $1.monthKey.year
                }
                return $0.monthKey.month > $1.monthKey.month
            }

            DispatchQueue.main.async {
                self.monthSummaries = nonEmptymonthSummaries
            }
        }
    }

    /// Used by:
    /// - SwipeReviewView.swift #deletionConfirmed
    /// 真正從 Photo Library 刪除照片（延後批次處理）
    func performPhysicalDeletion(_ assetIds: [String], completion: @escaping (PhotoPhysicalDeletionOutcome) -> Void) {

        let assetsToDelete = PHAsset.fetchAssets(withLocalIdentifiers: assetIds, options: nil)

        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assetsToDelete)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(.confirmed)
                } else if let error = error {
                    let nsError = error as NSError

                    if nsError.domain == PHPhotosErrorDomain {
                        if nsError.code == PHPhotosError.userCancelled.rawValue ||
                            nsError.code == PHPhotosError.operationInterrupted.rawValue {
                            completion(.cancelled)
                            return
                        }
                    }

                    completion(.failed(error))
                } else {
                    let unknownError = NSError(domain: "PhotoDeletion", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])
                    completion(.failed(unknownError))
                }
            }
        }
    }

    // MARK: - Private Helper Methods

    private func loadPersistedAssetState(for assetId: String) -> AssetItem? {
        guard let data = UserDefaults.standard.data(forKey: "asset_review_states"),
              let savedStates = try? JSONDecoder().decode([String: AssetItem].self, from: data) else {
            return nil
        }
        return savedStates[assetId]
    }

    private func getAllPersistedAssetStates() -> [String: AssetItem] {
        guard let data = UserDefaults.standard.data(forKey: "asset_review_states"),
              let savedStates = try? JSONDecoder().decode([String: AssetItem].self, from: data) else {
            return [:]
        }
        return savedStates
    }

    /// Used by:
    /// - SwipeReviewView.swift #updateStatistics
    func invalidateMonthStatistics(for monthKey: MonthKey) {
        let monthKeyString = monthKey.displayString

        monthStatisticsCache.removeValue(forKey: monthKeyString)
        allPersistedStatesCache = nil
        if let newSummary = recalculateMonthStatistics(for: monthKey, updateCache: true) {
            if let index = monthSummaries.firstIndex(where: { $0.monthKey == monthKey }) {
                monthSummaries[index] = newSummary
            }
        }
    }

    private func recalculateMonthStatistics(for monthKey: MonthKey, updateCache: Bool = false) -> MonthSummary? {
        let monthKeyString = monthKey.displayString
        guard let assets = assetsByMonth[monthKeyString] else { return nil }

        let allPersistedStates = getAllPersistedAssetStates()
        if updateCache {
            allPersistedStatesCache = allPersistedStates
        }

        let updatedAssets = assets.map { asset in
            allPersistedStates[asset.id] ?? asset
        }

        let keptCount = updatedAssets.filter { $0.isKept }.count
        let deleteQueuedCount = updatedAssets.filter { $0.isQueuedForDeletion }.count
        let reviewedCount = keptCount + deleteQueuedCount

        let summary = MonthSummary(
            monthKey: monthKey,
            totalCount: assets.count,
            reviewedCount: reviewedCount,
            keptCount: keptCount,
            deleteQueuedCount: deleteQueuedCount,
            skippedCount: 0
        )

        if updateCache {
            monthStatisticsCache[monthKeyString] = summary
        }

        return summary
    }

}

enum PhotoError: LocalizedError {
    case fetchFailed
    case deleteFailed
    case accessDenied

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "無法載入照片"
        case .deleteFailed:
            return "刪除照片失敗"
        case .accessDenied:
            return "無法存取照片庫"
        }
    }
}

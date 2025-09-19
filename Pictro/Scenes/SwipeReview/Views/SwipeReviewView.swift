//
//  SwipeReviewView.swift
//  Pictro
//
//  Created with Claude Code AI-driven development by William.
//  This is the main swipe review interface for photo management,
//  allowing users to quickly sort photos by swiping left (delete) or right (keep).
//
//  Copyright © 2025 Pictro. All rights reserved.
//

import SwiftUI
import Photos

struct SwipeReviewView: View {
    let monthKey: MonthKey
    @EnvironmentObject var photoLibraryService: PhotoLibraryService
    @EnvironmentObject var persistenceService: PersistenceService
    @EnvironmentObject var hapticsService: HapticsService
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: SwipeReviewViewModel?
    @State private var currentSwipeDirection: SwipeDirection? = nil
    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteQueue = false
    @State private var resetCardOffsetsFlag = false
    private let config = SwipeReviewConfig()

    enum SwipeDirection {
        case left, right
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let viewModel = viewModel {
                    headerView(viewModel: viewModel)
                    cardDeckArea(viewModel: viewModel)
                    controlButtons(viewModel: viewModel)
                } else {
                    ProgressView("載入中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle(monthKey.localizedDisplayString)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完成") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        // 刪除佇列按鈕
                        Button(action: {
                            showingDeleteQueue = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                if let count = viewModel?.deleted.count, count > 0 {
                                    Text("\(count)")
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.red)
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .disabled(viewModel?.deleted.isEmpty ?? true)

                        // 復原按鈕
                        Button("復原") {
                            viewModel?.undoLast()
                            resetCardOffsetsFlag.toggle()
                            currentSwipeDirection = nil
                            hapticsService.lightImpact()
                        }
                        .disabled(viewModel?.history.isEmpty ?? true)
                    }
                }
            }
        }
        .onAppear { setupViewModel() }
        .sheet(isPresented: $showingDeleteQueue) {
            if let viewModel = viewModel {
                DeletePhotoView(
                    viewModel: viewModel,
                    onConfirmDelete: { assetIds, finished in
                        Task {
                            await performActualDeletion(assetIds, completion: finished)
                        }
                    },
                    onCancel: {
                        showingDeleteQueue = false
                    },
                    onRestore: { assetIds in
                        viewModel.restoreAssets(assetIds)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            resetCardOffsetsFlag.toggle()
                            currentSwipeDirection = nil
                        }
                    }
                )
            }
        }
        .onChange(of: showingDeleteQueue) { _, isShowing in
            // 當刪除頁面關閉時刷新資料（使用本地快取，不重新 fetch）
            if !isShowing {
                viewModel?.refreshAssets()
            }
        }
    }
}
// MARK: - Subviews

private extension SwipeReviewView {
    func headerView(viewModel: SwipeReviewViewModel) -> some View {
        VStack(spacing: 12) {
            ProgressView(value: viewModel.totalProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .padding(.horizontal, 20)

            HStack(spacing: 24) {
                VStack {
                    Text("\(viewModel.kept.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("保留")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack {
                    Text("\(viewModel.deleted.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Text("刪除")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack {
                    Text("\(viewModel.deck.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("剩餘")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }

    func cardDeckArea(viewModel: SwipeReviewViewModel) -> some View {
        ZStack {
            if viewModel.deck.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.green)

                    Text("已全部處理完成！")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("保留了 \(viewModel.kept.count) 張照片")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            } else {
                SwipeReviewDeck(
                    viewModel: viewModel,
                    config: config,
                    resetCardOffsets: resetCardOffsetsFlag,
                    onSwipeDirectionChange: { currentSwipeDirection = $0 }
                )
                .onChange(of: viewModel.deck.count) { _, _ in
                    DispatchQueue.main.async {
                        currentSwipeDirection = nil
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }

    func controlButtons(viewModel: SwipeReviewViewModel) -> some View {
        HStack(spacing: 24) {
            // 刪除按鈕
            Button(action: {
                guard let top = viewModel.deck.first else { return }
                viewModel.applyDecision(.delete(top))
                viewModel.popTopCard()
            }) {
                let isActive = currentSwipeDirection == .left

                Image(systemName: "xmark")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(isActive ? .white : .red)
                    .frame(width: 70, height: 70)
                    .background(isActive ? Color.red : Color.white)
                    .overlay(
                        Circle()
                            .stroke(Color.red, lineWidth: isActive ? 0 : 2)
                    )
                    .clipShape(Circle())
                    .scaleEffect(isActive ? 1.0 : 0.86)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
            }
            .disabled(viewModel.deck.isEmpty)

            Spacer()

            // 保留按鈕
            Button(action: {
                guard let top = viewModel.deck.first else { return }
                viewModel.applyDecision(.keep(top))
                viewModel.popTopCard()
            }) {
                let isActive = currentSwipeDirection == .right

                Image(systemName: "heart.fill")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(isActive ? .white : .green)
                    .frame(width: 70, height: 70)
                    .background(isActive ? Color.green : Color.white)
                    .overlay(
                        Circle()
                            .stroke(Color.green, lineWidth: isActive ? 0 : 2)
                    )
                    .clipShape(Circle())
                    .scaleEffect(isActive ? 1.0 : 0.86)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
            }
            .disabled(viewModel.deck.isEmpty)
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 30)
    }
}

// MARK: - Private Helpers

private extension SwipeReviewView {
    func performActualDeletion(_ assetIds: [String], completion: @escaping (Bool) -> Void) async {
        guard let viewModel = viewModel else {
            completion(false)
            return
        }

        hapticsService.deleteConfirmed()

        return await withCheckedContinuation { continuation in
            Task { @MainActor in
                await self.photoLibraryService.performPhysicalDeletion(assetIds) { outcome in
                    DispatchQueue.main.async {
                        switch outcome {
                        case .confirmed:
                            self.photoLibraryService.addToLocalBlacklist(assetIds)
                            viewModel.removeDeletedAssets(assetIds)
                            self.persistenceService.removeFromDeleteQueue(assetIds)
                            self.persistenceService.removeAssetReviewStates(for: assetIds)
                            completion(true)
                        case .cancelled:
                            self.hapticsService.lightImpact()
                            completion(false)
                        case .failed(let error):
                            self.hapticsService.errorOccurred()
                            completion(false)
                        }

                        continuation.resume()
                    }
                }
            }
        }
    }

    func setupViewModel() {
        guard viewModel == nil else { return }

        let newViewModel = SwipeReviewViewModel(
            monthKey: monthKey,
            photoLibraryService: photoLibraryService,
            persistenceService: persistenceService
        )

        newViewModel.onDecision = { decision in
            hapticsService.lightImpact()
        }

        newViewModel.onComplete = {
            hapticsService.successFeedback()
        }

        viewModel = newViewModel
    }
}

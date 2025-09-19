//
//  DeletePhotoView.swift
//  Pictro
//
//  Created with Claude Code AI-driven development by William.
//  Copyright © 2025 Pictro. All rights reserved.

import SwiftUI

struct DeletePhotoView: View {
    @ObservedObject var viewModel: SwipeReviewViewModel // 動態響應 deleted 變化
    let onConfirmDelete: (_ assetIds: [String], _ completion: @escaping (Bool) -> Void) -> Void
    let onCancel: () -> Void
    let onRestore: ([String]) -> Void

    @State private var selectedAssets: Set<String> = []
    @State private var isDeleting = false
    @EnvironmentObject var photoLibraryService: PhotoLibraryService

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if assetsToDelete.isEmpty {
                    emptyStateView
                } else {
                    headerView
                    assetGridView
                    bottomActionView
                }
            }
            .navigationTitle("刪除佇列")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: assetsToDelete) { _, newAssets in
                // 當 assetsToDelete 變化時，清理無效的選擇
                let validAssetIds = Set(newAssets.map { $0.id })
                selectedAssets = selectedAssets.intersection(validAssetIds)

                // 如果刪除操作完成（被選中的照片已經不在列表中），結束 loading 狀態
                if isDeleting && selectedAssets.isEmpty {
                    isDeleting = false
                }

            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { onCancel() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("全選") {
                            if selectedAssets.count == assetsToDelete.count {
                                selectedAssets.removeAll()
                            } else {
                                selectedAssets = Set(assetsToDelete.map { $0.id })
                            }
                        }
                        .disabled(assetsToDelete.isEmpty)

                        if !selectedAssets.isEmpty {
                            Divider()

                            Button("回復選中項目") {
                                onRestore(Array(selectedAssets))
                                onCancel() // 關閉頁面
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear {
            // 預設全選
            selectedAssets = Set(assetsToDelete.map { $0.id })
        }
    }
}

// MARK: - Private Helpers

private extension DeletePhotoView {
    var assetsToDelete: [AssetItem] { viewModel.deleted }

    func performDeletion() async {
        let assetsToDelete = Array(selectedAssets)
        isDeleting = true
        onConfirmDelete(assetsToDelete) { success in
            isDeleting = false
        }
    }
}

// MARK: - Subviews

private extension DeletePhotoView {
    var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "trash.slash")
                .font(.system(size: 64))
                .foregroundColor(.gray)

            Text("沒有要刪除的照片")
                .font(.title2)
                .fontWeight(.semibold)

            Text("所有標記為刪除的照片會顯示在這裡")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var headerView: some View {
        VStack(spacing: 8) {
            Text("即將刪除 \(assetsToDelete.count) 張照片")
                .font(.headline)
                .foregroundColor(.primary)

            Text("已選擇 \(selectedAssets.count) 張")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("⚠️ 此操作無法復原")
                .font(.caption)
                .foregroundColor(.red)
                .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemGray6))
    }

    var assetGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(assetsToDelete, id: \.id) { asset in
                    DeletePhotoThumbnailView(
                        asset: asset,
                        isSelected: selectedAssets.contains(asset.id),
                        onToggle: {
                            if selectedAssets.contains(asset.id) {
                                selectedAssets.remove(asset.id)
                            } else {
                                selectedAssets.insert(asset.id)
                            }
                        }
                    )
                }
            }
            .padding()
        }
    }

    var bottomActionView: some View {
        VStack(spacing: 12) {
            // 回復按鈕
            Button(action: {
                onRestore(Array(selectedAssets))
                onCancel() // 關閉頁面
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("回復 \(selectedAssets.count) 張照片")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(12)
            }
            .disabled(selectedAssets.isEmpty)

            // 永久刪除按鈕
            Button(action: {
                Task {
                    await performDeletion()
                }
            }) {
                HStack {
                    if isDeleting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text("刪除中...")
                    } else {
                        Image(systemName: "trash.fill")
                        Text("永久刪除 \(selectedAssets.count) 張照片")
                    }
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isDeleting ? Color.gray : Color.red)
                .cornerRadius(12)
            }
            .disabled(selectedAssets.isEmpty || isDeleting)

            Button("取消") {
                onCancel()
            }
            .font(.body)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

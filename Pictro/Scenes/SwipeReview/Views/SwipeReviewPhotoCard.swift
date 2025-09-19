//
//  SwipeReviewPhotoCard.swift
//  Pictro
//
//  Created with Claude Code AI-driven development by William.
//  Copyright © 2025 Pictro. All rights reserved.
//

import SwiftUI

struct SwipeReviewPhotoCard: View {
    let asset: AssetItem
    let onTap: (() -> Void)?
    @EnvironmentObject var photoLibraryService: PhotoLibraryService
    @State private var image: UIImage?
    @State private var isLoading = true

    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white)
            .overlay {
                VStack(spacing: 0) {
                    imageDisplayArea
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.08), radius: 1, x: 0, y: 1)
            .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
            .shadow(color: .black.opacity(0.04), radius: 16, x: 0, y: 8)
            .id(asset.id)
            .onTapGesture { onTap?() }
            .onAppear { loadImage() }
            .onChange(of: asset.id) { _, _ in
                // Reset state when asset ID changes
                image = nil
                isLoading = true
                loadImage()
            }
    }

    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }()
}

// MARK: - Subviews

private extension SwipeReviewPhotoCard {
    var imageDisplayArea: some View {
        GeometryReader { geometry in
            ZStack {
                // Gray background
                Rectangle()
                    .fill(Color.gray.opacity(0.05))

                // Image / Loading / Error
                Group {
                    if let image = image {
                        let imageDisplaySize = calculateImageDisplaySize(
                            containerSize: geometry.size,
                            imageSize: CGSize(width: image.size.width, height: image.size.height)
                        )

                        ZStack {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .blur(radius: 15)
                                .opacity(0.2)

                            VStack(spacing: 0) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: imageDisplaySize.width, height: imageDisplaySize.height - 32) // 減去日期標籤的高度
                                    .clipShape(Rectangle())

                                // Date label
                                HStack {
                                    Spacer()
                                    Text(formatter.string(from: asset.creationDate ?? Date()))
                                        .font(.callout)
                                        .foregroundColor(.white)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                }
                                .background(
                                    Rectangle()
                                        .fill(Color.black.opacity(0.8))
                                )
                                .frame(width: imageDisplaySize.width)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .position(
                                x: geometry.size.width / 2,
                                y: geometry.size.height / 2
                            )
                        }

                    } else if isLoading {
                        ProgressView()
                            .scaleEffect(1.2)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("無法載入")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .clipped()
    }
}

// MARK: - Private Helpers

private extension SwipeReviewPhotoCard {
    // 計算圖片顯示尺寸，確保 padding 不被吃掉
    func calculateImageDisplaySize(containerSize: CGSize, imageSize: CGSize) -> CGSize {
        // 為 padding 預留空間
        let paddingReserve: CGFloat = 12 // 上下左右各預留 6pt
        let availableWidth = containerSize.width - paddingReserve
        let availableHeight = containerSize.height - paddingReserve

        // 計算圖片的長寬比
        let imageAspectRatio = imageSize.width / imageSize.height
        let containerAspectRatio = availableWidth / availableHeight

        var displayWidth: CGFloat
        var displayHeight: CGFloat

        if imageAspectRatio > containerAspectRatio {
            // 圖片較寬，以寬度為準
            displayWidth = availableWidth
            displayHeight = availableWidth / imageAspectRatio
        } else {
            // 圖片較高，以高度為準
            displayHeight = availableHeight
            displayWidth = availableHeight * imageAspectRatio
        }

        return CGSize(width: displayWidth, height: displayHeight)
    }

    func loadImage() {
        let targetSize = CGSize(width: 400, height: 600)
        photoLibraryService.loadImage(for: asset, targetSize: targetSize) { loadedImage in
            DispatchQueue.main.async {
                self.image = loadedImage
                self.isLoading = false
            }
        }
    }
}

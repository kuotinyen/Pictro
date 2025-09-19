//
//  DeletePhotoAssetThumbnailView.swift
//  Pictro
//
//  Created with Claude Code AI-driven development by William.
//  Copyright © 2025 Pictro. All rights reserved.

import SwiftUI

struct DeletePhotoThumbnailView: View {
    let asset: AssetItem
    let isSelected: Bool
    let onToggle: () -> Void

    @EnvironmentObject var photoLibraryService: PhotoLibraryService
    @State private var thumbnail: UIImage?

    var body: some View {
        Button(action: onToggle) {
            ZStack(alignment: .topTrailing) {
                // Background shape with fixed square aspect
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(1, contentMode: .fit)

                // Image or placeholder
                Group {
                    if let thumbnail = thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                            .clipped()
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.9)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                // Selection indicator (top-right)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .white)
                    .shadow(radius: 2)
                    .padding(8)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
            )
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(Text(isSelected ? "已選取縮圖" : "未選取縮圖"))
        .onAppear {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        let thumbnailSize = CGSize(width: 150, height: 150)
        photoLibraryService.loadImage(for: asset, targetSize: thumbnailSize) { image in
            DispatchQueue.main.async {
                self.thumbnail = image
            }
        }
    }
}

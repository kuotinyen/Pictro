//
//  EmptyStateView.swift
//  Pictro
//
//  Created with Claude Code AI-driven development by William.
//  This view displays when no photos are found in the user's library,
//  providing options to reload or check permissions.
//
//  Copyright © 2025 Pictro. All rights reserved.
//

import SwiftUI

struct EmptyStateView: View {
    @EnvironmentObject var photoLibraryService: PhotoLibraryService

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.badge.questionmark")
                .font(.system(size: 64))
                .foregroundColor(.gray)

            Text("沒有找到照片")
                .font(.title2)
                .fontWeight(.semibold)

            Text("您的照片庫中沒有找到照片，或權限設定有問題")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button("重新載入") {
                photoLibraryService.forceReload()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
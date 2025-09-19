//
//  ErrorView.swift
//  Pictro
//
//  Created with Claude Code AI-driven development by William.
//  This view displays error messages when photo library operations fail,
//  providing retry options for users.
//
//  Copyright © 2025 Pictro. All rights reserved.
//

import SwiftUI

struct ErrorView: View {
    let error: Error
    @EnvironmentObject var photoLibraryService: PhotoLibraryService

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)

            Text("發生錯誤")
                .font(.title2)
                .fontWeight(.semibold)

            Text(error.localizedDescription)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button("重試") {
                photoLibraryService.requestPermission()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
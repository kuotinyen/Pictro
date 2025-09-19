//
//  PermissionRequestView.swift
//  Pictro
//
//  Created with Claude Code AI-driven development by William.
//  This view displays a welcome screen prompting users to grant
//  photo library access permissions with clear instructions.
//
//  Copyright © 2025 Pictro. All rights reserved.
//

import SwiftUI

struct PermissionRequestView: View {
    @EnvironmentObject var photoLibraryService: PhotoLibraryService

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.fill")
                .font(.system(size: 64))
                .foregroundColor(.blue)

            Text("歡迎使用 Pictro")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("我們需要存取您的照片庫來幫助您整理照片")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button("允許存取照片") {
                photoLibraryService.requestPermission()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}
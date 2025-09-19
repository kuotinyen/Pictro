//
//  PermissionDeniedView.swift
//  Pictro
//
//  Created with Claude Code AI-driven development by William.
//  This view displays when photo library access is denied,
//  providing instructions to enable permissions through Settings.
//
//  Copyright © 2025 Pictro. All rights reserved.
//

import SwiftUI

struct PermissionDeniedView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.badge.exclamationmark.fill")
                .font(.system(size: 64))
                .foregroundColor(.red)

            Text("需要照片權限")
                .font(.title)
                .fontWeight(.semibold)

            Text("請到「設定」>「隱私權與安全性」>「照片」中允許 Pictro 存取您的照片")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button("開啟設定") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
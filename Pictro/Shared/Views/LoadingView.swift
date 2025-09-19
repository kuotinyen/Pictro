//
//  LoadingView.swift
//  Pictro
//
//  Created with Claude Code AI-driven development by William.
//  This view displays a loading indicator while the application
//  is processing photo library assets.
//
//  Copyright © 2025 Pictro. All rights reserved.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在載入照片...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
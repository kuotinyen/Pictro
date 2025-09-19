//
//  SwipeReviewConfig.swift
//  Pictro
//
//  Created with Claude Code AI-driven development by William.
//  Copyright © 2025 Pictro. All rights reserved.
//

import Foundation

struct SwipeReviewConfig {
    /// 觸發滑出判定的位移（相對於寬度比例）
    var triggerRatio: CGFloat = 0.28
    /// 慣性速度閾值（pt/s），超過也視為滑出
    var velocityThreshold: CGFloat = 900
    /// 頂部可交互的卡片數（一般只需 1，但展示疊放常見 3）
    var visibleTopCount: Int = 3
    /// 疊放的 y 位移步進 - 增加間距讓卡片更分開
    var stackYOffset: CGFloat = 20
    /// 疊放的縮放步進 - 增加縮放差異讓後面卡片更明顯縮小
    var stackScaleStep: CGFloat = 0.08
    /// 最大旋轉角（度） - 頂層卡片拖拽時的旋轉
    var maxRotation: Double = 8
    /// 滑出動畫時間
    var flingDuration: Double = 0.22
    /// 卡片堆疊最大顯示數量（超過此數量的卡片將完全透明）
    var maxVisibleCards: Int = 3
}

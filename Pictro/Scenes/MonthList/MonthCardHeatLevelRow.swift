//
//  MonthCardHeatLevelRow.swift
//  Pictro
//
//  Created with Claude Code AI-driven development by William.
//  This view displays a visual heat level representation based on photo count,
//  showing intensity levels through colored squares similar to GitHub contribution graph.
//
//  Copyright © 2025 Pictro. All rights reserved.
//

import SwiftUI

// MARK: - Data Models

/// 色盤設定：active 層級顏色（索引 0..n），以及 inactive 色彩
struct MonthCardHeatPalette {
    var activeLevels: [Color]
    var inactive: Color
    var inactiveOpacity: CGFloat

    init(
        activeLevels: [Color],
        inactive: Color = Color(.systemGray6),
        inactiveOpacity: CGFloat = 0.3
    ) {
        self.activeLevels = activeLevels
        self.inactive = inactive
        self.inactiveOpacity = inactiveOpacity
    }

    /// 預設色盤：灰→藍→綠→黃→橘→紅→紫
    static let `default` = MonthCardHeatPalette(
        activeLevels: [
            Color(.systemGray5),
            Color(.systemBlue).opacity(0.30),
            Color(.systemBlue).opacity(0.60),
            Color(.systemGreen).opacity(0.60),
            Color(.systemYellow).opacity(0.80),
            Color(.systemOrange).opacity(0.80),
            Color(.systemRed).opacity(0.80),
            Color(.systemPurple).opacity(0.90)
        ],
        inactive: Color(.systemGray6),
        inactiveOpacity: 0.30
    )
}

// MARK: - View

struct MonthCardHeatLevelRow: View {
    // Inputs
    let totalCount: Int
    let completionRate: Double

    var thresholds: [Int] = [0, 150, 300, 600, 900, 1200, 1500]
    var columns: Int = 7                   // 顯示幾個方塊
    var cellSize: CGSize = .init(width: 12, height: 12)
    var cellCornerRadius: CGFloat = 2
    var cellSpacing: CGFloat = 2
    var verticalPadding: CGFloat = 2
    var palette: MonthCardHeatPalette = .default

    init(
        totalCount: Int,
        completionRate: Double,
        thresholds: [Int] = [0, 150, 300, 600, 900, 1200, 1500],
        columns: Int = 7,
        cellSize: CGSize = .init(width: 12, height: 12),
        cellCornerRadius: CGFloat = 2,
        cellSpacing: CGFloat = 2,
        verticalPadding: CGFloat = 2,
        palette: MonthCardHeatPalette = .default
    ) {
        self.totalCount = totalCount
        self.completionRate = completionRate
        self.thresholds = thresholds
        self.columns = columns
        self.cellSize = cellSize
        self.cellCornerRadius = cellCornerRadius
        self.cellSpacing = cellSpacing
        self.verticalPadding = verticalPadding
        self.palette = palette
    }

    private var level: Int {
        let maxLevel = palette.activeLevels.count - 1
        return heatLevel(for: totalCount, thresholds: thresholds, maxLevel: maxLevel)
    }

    var body: some View {
        HStack(spacing: cellSpacing) {
            ForEach(0..<columns, id: \.self) { index in
                RoundedRectangle(cornerRadius: cellCornerRadius, style: .continuous)
                    .fill(colorForCell(index: index, level: level, palette: palette))
                    .frame(width: cellSize.width, height: cellSize.height)
            }
        }
        .padding(.vertical, verticalPadding)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityDescription))
    }
}

// MARK: - Private Helpers

private extension MonthCardHeatLevelRow {
    func heatLevel(for count: Int, thresholds: [Int], maxLevel: Int) -> Int {
        guard !thresholds.isEmpty else { return 0 }
        let idx = thresholds.lastIndex(where: { $0 <= count }) ?? 0
        return min(idx, maxLevel)
    }

    func colorForCell(index: Int, level: Int, palette: MonthCardHeatPalette) -> Color {
        if index <= level {
            let clamped = min(index, palette.activeLevels.count - 1)
            return palette.activeLevels[clamped]
        } else {
            return palette.inactive.opacity(palette.inactiveOpacity)
        }
    }

    var accessibilityDescription: String {
        // 例如：「熱度 4，共 680 張照片」
        "Heat level \(level), total \(totalCount) photos"
    }
}

// MARK: - Preview

#Preview("HeatLevelRow - default") {
    VStack(alignment: .leading, spacing: 12) {
        MonthCardHeatLevelRow(totalCount: 0, completionRate: 0.0)
        MonthCardHeatLevelRow(totalCount: 120, completionRate: 0.0)
        MonthCardHeatLevelRow(totalCount: 280, completionRate: 0.0)
        MonthCardHeatLevelRow(totalCount: 580, completionRate: 0.0)
        MonthCardHeatLevelRow(totalCount: 880, completionRate: 0.0)
        MonthCardHeatLevelRow(totalCount: 1180, completionRate: 0.0)
        MonthCardHeatLevelRow(totalCount: 1480, completionRate: 0.0)
        MonthCardHeatLevelRow(totalCount: 1800, completionRate: 0.0)
    }
    .padding()
}

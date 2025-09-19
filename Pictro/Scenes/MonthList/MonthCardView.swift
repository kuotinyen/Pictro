//
//  MonthCardView.swift
//  Pictro
//
//  Created with Claude Code AI-driven development by William.
//  This view represents a single month card showing photo count,
//  completion status, and heat level visualization.
//
//  Copyright © 2025 Pictro. All rights reserved.
//

import SwiftUI

struct MonthCardView: View {
    let summary: MonthSummary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                Text("\(summary.monthKey.month) 月")
                    .font(.headline)
                    .fontWeight(.semibold)

                // Status Row
                HStack {
                    if summary.isCompleted {
                        completionBadge
                    } else {
                        remainingCountText
                    }

                    Spacer()

                    if summary.completionRate > 0 {
                        percentageText
                    }
                }

                // Heat visualization
                MonthCardHeatLevelRow(totalCount: summary.totalCount, completionRate: summary.completionRate)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("點擊查看該月份的照片。")
    }
}

// MARK: - Subviews

private extension MonthCardView {
    var completionBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
            Text("全部完成")
        }
        .font(.caption2)
        .foregroundColor(.green)
    }

    var remainingCountText: some View {
        HStack(alignment: .lastTextBaseline, spacing: 4) {
            Text("\(summary.remainingCount)")
            Text("張照片")
        }
        .foregroundColor(.secondary)
        .font(.caption2)
    }

    var percentageText: some View {
        Text(summary.completionRate, format: .percent.precision(.fractionLength(0)))
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(summary.completionRate == 1.0 ? .green : .blue)
    }

    var accessibilityLabel: Text {
        let monthText = "\(summary.monthKey.month) 月"
        let statusText: String
        if summary.isCompleted {
            statusText = "全部完成"
        } else {
            statusText = "剩餘 \(summary.remainingCount) 張"
        }
        let percent: String = summary.completionRate > 0 ?
            "，完成率 \(Int(summary.completionRate * 100))%" : ""
        return Text(monthText + "，" + statusText + percent)
    }
}

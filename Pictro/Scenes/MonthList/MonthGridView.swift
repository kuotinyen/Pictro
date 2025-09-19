//
//  MonthGridView.swift
//  Pictro
//
//  Created with Claude Code AI-driven development by William.
//  This view displays months in a grid layout organized by year,
//  showing month cards with statistics and completion status.
//
//  Copyright © 2025 Pictro. All rights reserved.
//

import SwiftUI

struct MonthGridView: View {
    @EnvironmentObject var photoLibraryService: PhotoLibraryService
    @Binding var selectedMonth: MonthKey?

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    private var groupedByYear: [(Int, [MonthSummary])] {
        let grouped = Dictionary(grouping: photoLibraryService.monthSummaries) { $0.monthKey.year }
        return grouped.sorted { $0.key > $1.key }
            .map { (year, summaries) in
                (year, summaries.sorted { $0.monthKey.month > $1.monthKey.month })
            }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20, pinnedViews: [.sectionHeaders]) {
                ForEach(groupedByYear, id: \.0) { year, summaries in
                    Section {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(summaries, id: \.monthKey) { summary in
                                MonthCardView(summary: summary) {
                                    selectedMonth = summary.monthKey
                                }
                            }
                        }
                        .padding(.horizontal)
                    } header: {
                        sectionHeader(year: year)
                    }
                }
            }
            .padding(.bottom)
        }
    }

    private func sectionHeader(year: Int) -> some View {
        HStack {
            Text("\(year) 年")
                .font(.title)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

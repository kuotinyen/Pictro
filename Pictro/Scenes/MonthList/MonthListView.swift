//
//  MonthListView.swift
//  Pictro
//
//  Created with Claude Code AI-driven development by William.
//  This is the main view for displaying photo library organized by months,
//  handling permission states and navigation to photo review interface.
//
//  Copyright © 2025 Pictro. All rights reserved.
//

import SwiftUI

struct MonthListView: View {
    @EnvironmentObject var photoLibraryService: PhotoLibraryService
    @EnvironmentObject var persistenceService: PersistenceService
    @EnvironmentObject var hapticsService: HapticsService

    @State private var selectedMonth: MonthKey?

    private var totalPhotosCount: Int {
        photoLibraryService.monthSummaries.reduce(0) { $0 + $1.totalCount }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {

                // Main Content
                Group {
                    switch photoLibraryService.authorizationStatus {
                    case .requestingPermission:
                        PermissionRequestView()
                    case .permissionDenied:
                        PermissionDeniedView()
                    case .loadingAssets:
                        LoadingView()
                    case .ready:
                        if photoLibraryService.monthSummaries.isEmpty {
                            EmptyStateView()
                        } else {
                            MonthGridView(selectedMonth: $selectedMonth)
                        }
                    case .error(let error):
                        ErrorView(error: error)
                    }
                }
            }
            .navigationTitle("共 \(totalPhotosCount) 張照片")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                photoLibraryService.forceReload()
            }
        }
        .fullScreenCover(item: $selectedMonth) { monthKey in
            SwipeReviewView(monthKey: monthKey)
        }
        .onAppear {
            if case .requestingPermission = photoLibraryService.authorizationStatus {
                photoLibraryService.requestPermission()
            }
        }
    }
}

// MARK: - Previews

#Preview {
    MonthListView()
        .environmentObject(PhotoLibraryService())
        .environmentObject(PersistenceService())
        .environmentObject(HapticsService())
}

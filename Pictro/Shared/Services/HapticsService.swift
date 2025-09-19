//
//  HapticsService.swift
//  Pictro
//
//  Created with Claude Code AI-driven development by William.
//  This file provides haptic feedback functionality for enhanced user interactions
//  throughout the Pictro photo management application.
//
//  Copyright © 2025 Pictro. All rights reserved.
//

import SwiftUI
import UIKit

class HapticsService: ObservableObject {
    @Published var isEnabled: Bool = true

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    init() {
        prepareGenerators()
    }

    private func prepareGenerators() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }

    // MARK: - Public Haptic Methods

    // Used by:
    // - ReviewCardView.swift#dragGesture
    func cardSwipeThresholdReached(for action: HapticAction) {
        guard isEnabled else { return }

        switch action {
        case .keep:
            impactMedium.impactOccurred()
        case .queueForDeletion:
            impactHeavy.impactOccurred()
        case .skip:
            impactLight.impactOccurred()
        }
    }

    // Used by:
    // - ReviewViewModel.swift#swipeCard
    func cardSwipeCompleted(for action: HapticAction) {
        guard isEnabled else { return }

        switch action {
        case .keep:
            notificationGenerator.notificationOccurred(.success)
        case .queueForDeletion:
            notificationGenerator.notificationOccurred(.warning)
        case .skip:
            impactLight.impactOccurred()
        }
    }

    // Used by:
    // - ReviewViewModel.swift#performUndo
    func undoAction() {
        guard isEnabled else { return }
        impactMedium.impactOccurred()
    }

    // Used by:
    // - ReviewViewModel.swift#completeReview
    func monthCompleted() {
        guard isEnabled else { return }

        // Create a celebration pattern
        DispatchQueue.main.async {
            self.notificationGenerator.notificationOccurred(.success)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impactMedium.impactOccurred()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.impactLight.impactOccurred()
        }
    }

    // Used by:
    // - SwipeReviewView.swift#buttonTapped
    func buttonPressed() {
        guard isEnabled else { return }
        selectionGenerator.selectionChanged()
    }

    // Used by:
    // - SwipeReviewView.swift#deleteConfirmation
    func deleteConfirmed() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.warning)
    }

    // Used by:
    // - SwipeReviewView.swift#errorHandling
    func errorOccurred() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.error)
    }

    // Used by:
    // - SwipeReviewView.swift#buttonActions
    // - MonthListView.swift#buttonActions
    func lightImpact() {
        guard isEnabled else { return }
        impactLight.impactOccurred()
    }

    // Used by:
    // - SwipeReviewView.swift#successActions
    // - MonthListView.swift#successActions
    func successFeedback() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
    }
}

//
//  SwipeReviewCard.swift
//  Pictro
//
//  Created with Claude Code AI-driven development by William.
//  Copyright © 2025 Pictro. All rights reserved.
//

import SwiftUI

struct SwipeReviewCard: View {
    let asset: AssetItem
    let isTop: Bool
    let stackIndex: Int
    let stackCount: Int
    let config: SwipeReviewConfig
    let containerSize: CGSize
    let cardOffset: CGSize
    let onOffsetChange: (CGSize) -> Void
    let onCommit: (SwipeReviewDecision) -> Void
    let onCancel: () -> Void

    @EnvironmentObject var photoLibraryService: PhotoLibraryService
    @State private var dragTranslation: CGSize = .zero
    @State private var isAnimatingOut: Bool = false
    @State private var cardID = UUID()

    var body: some View {
        cardMainView
            .scaleEffect(stackedScale)
            .offset(x: stackedXOffset, y: stackedYOffset)
            .rotationEffect(stackRotation)
            .opacity(cardOpacity)
            .offset(totalTranslation)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: stackedScale)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: stackedYOffset)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: stackedXOffset)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: cardOpacity)
            .animation(.spring(response: 0.28, dampingFraction: 0.88), value: totalTranslation)
            .animation(.spring(response: 0.28, dampingFraction: 0.88), value: stackRotation)
            .gesture(isTop ? dragGesture : nil)
            .id(cardID)
            .onChange(of: dragTranslation) { _, newValue in
                if isTop { onOffsetChange(newValue) }
            }
    }
}

// MARK: - Subviews

private extension SwipeReviewCard {
    var cardMainView: some View {
        ZStack {
            SwipeReviewPhotoCard(asset: asset, onTap: {  })
                .overlay(alignment: .topLeading) {
                    if isTop {
                        let w = totalTranslation.width
                        if w > 20 {
                            keepBadge(opacity: min(1, Double(w / 120)))
                        }
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if isTop {
                        let w = totalTranslation.width
                        if w < -20 {
                            deleteBadge(opacity: min(1, Double(-w / 120)))
                        }
                    }
                }
        }
    }

    @ViewBuilder
    func keepBadge(opacity: Double) -> some View {
        Text("保留")
            .font(.system(.body, design: .rounded).weight(.bold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.green, in: Capsule())
            .foregroundColor(.white)
            .padding(16)
            .opacity(opacity)
    }

    @ViewBuilder
    func deleteBadge(opacity: Double) -> some View {
        Text("刪除")
            .font(.system(.body, design: .rounded).weight(.bold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.red, in: Capsule())
            .foregroundColor(.white)
            .padding(16)
            .opacity(opacity)
    }
}

// MARK: - Private Helpers

private extension SwipeReviewCard {
    // 計算最終的位移（拖拽 + 外部設定的 offset）
    var totalTranslation: CGSize {
        CGSize(
            width: dragTranslation.width + cardOffset.width,
            height: dragTranslation.height + cardOffset.height
        )
    }

    var rotation: Angle {
        guard isTop else { return .zero }
        let progress = max(-1, min(1, totalTranslation.width / max(containerSize.width, 1)))
        return .degrees(Double(progress) * config.maxRotation)
    }

    var cardOpacity: Double {
        if stackIndex >= config.visibleTopCount { return 0 }
        let opacityStep = 0.15
        return 1.0 - (Double(stackIndex) * opacityStep)
    }

    var stackRotation: Angle { isTop ? rotation : .zero }

    var stackedScale: CGSize {
        let position = stackIndex
        let scaleReduction = CGFloat(position) * config.stackScaleStep
        let scale = 1.0 - scaleReduction
        let finalScale = max(0.85, scale)
        return CGSize(width: finalScale, height: finalScale)
    }

    var stackedYOffset: CGFloat {
        var offsetY: CGFloat = 0
        let firstCardHeight = containerSize.height
        let heightDiffBetweenCards = (config.stackScaleStep * 2) * firstCardHeight
        for idx in 0..<stackIndex {
            let currentHeight = firstCardHeight - CGFloat(idx) * heightDiffBetweenCards
            let nextHeight = firstCardHeight - CGFloat(idx + 1) * heightDiffBetweenCards
            let centerPointDistance = (currentHeight - nextHeight) / 2
            offsetY += (centerPointDistance + config.stackYOffset)
        }
        return offsetY
    }

    var stackedXOffset: CGFloat {
        let horizontalInset = CGFloat(stackIndex) * 12
        return horizontalInset / 2
    }

    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .local)
            .onChanged { value in
                let maxYOffset: CGFloat = 60
                let dampingFactor: CGFloat = 0.3
                let dampedY = value.translation.height * dampingFactor
                let constrainedY = max(-maxYOffset, min(maxYOffset, dampedY))
                dragTranslation = CGSize(width: value.translation.width, height: constrainedY)
            }
            .onEnded { value in
                decide(value: value)
            }
    }

    func decide(value: DragGesture.Value) {
        let width = containerSize.width
        let ratio = max(0.0001, width) * config.triggerRatio
        let vx = value.predictedEndLocation.x - value.location.x
        let time: CGFloat = 0.15
        let velocityX = vx / time

        let dx = value.translation.width
        let shouldFlingRight = dx > ratio || velocityX > config.velocityThreshold
        let shouldFlingLeft = dx < -ratio || velocityX < -config.velocityThreshold

        if shouldFlingRight || shouldFlingLeft {
            let direction: SwipeReviewProgrammaticDirection = shouldFlingRight ? .keep : .delete
            flingOut(direction)
        } else {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                dragTranslation = .zero
            }
            onCancel()
        }
    }

    func flingOut(_ direction: SwipeReviewProgrammaticDirection) {
        isAnimatingOut = true
        let xTarget: CGFloat = (direction == .keep) ? containerSize.width * 1.4 : -containerSize.width * 1.4
        onOffsetChange(.zero)
        withAnimation(.easeIn(duration: config.flingDuration)) {
            dragTranslation = CGSize(width: xTarget, height: dragTranslation.height)
        }
        let decision: SwipeReviewDecision = (direction == .keep) ? .keep(asset) : .delete(asset)
        onCommit(decision)
        DispatchQueue.main.asyncAfter(deadline: .now() + config.flingDuration) {
            dragTranslation = .zero
            cardID = UUID()
            isAnimatingOut = false
        }
    }
}

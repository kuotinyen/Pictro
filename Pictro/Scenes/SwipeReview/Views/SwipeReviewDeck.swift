//
//  SwipeReviewDeck.swift
//  Pictro
//
//  Created with Claude Code AI-driven development by William.
//  Copyright © 2025 Pictro. All rights reserved.
//

import SwiftUI

struct SwipeReviewDeck: View {
    @ObservedObject var viewModel: SwipeReviewViewModel
    let config: SwipeReviewConfig
    let resetCardOffsets: Bool
    let onSwipeDirectionChange: (SwipeReviewView.SwipeDirection?) -> Void

    @State private var cardOffsets: [String: CGSize] = [:]
    @State private var isAnimating = false
    @EnvironmentObject var photoLibraryService: PhotoLibraryService

    var body: some View {
        GeometryReader { geo in
            cardStack(in: geo.size)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .onChange(of: resetCardOffsets) { _, _ in
            cardOffsets.removeAll()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                preloadNextCards()
            }
        }
    }
}

// MARK: - Subviews

private extension SwipeReviewDeck {
    @ViewBuilder
    func cardStack(in containerSize: CGSize) -> some View {
        ZStack {
            let cards = Array(viewModel.deck.prefix(config.visibleTopCount))

            ForEach(Array(cards.enumerated().reversed()), id: \.element.id) { idx, asset in
                let isTop = idx == 0
                let cardId = asset.id

                SwipeReviewCard(
                    asset: asset,
                    isTop: isTop,
                    stackIndex: idx,
                    stackCount: cards.count,
                    config: config,
                    containerSize: containerSize,
                    cardOffset: cardOffsets[cardId] ?? .zero,
                    onOffsetChange: { offset in
                        // 只有頂層卡片的 offset 會被記錄
                        if isTop {
                            cardOffsets[cardId] = offset

                            let threshold: CGFloat = 30
                            if offset.width > threshold {
                                onSwipeDirectionChange(.right)
                            } else if offset.width < -threshold {
                                onSwipeDirectionChange(.left)
                            } else {
                                onSwipeDirectionChange(nil)
                            }
                        } else if offset == .zero {
                            onSwipeDirectionChange(nil)
                        }
                    },
                    onCommit: { decision in
                        isAnimating = true
                        cardOffsets.removeValue(forKey: cardId)
                        viewModel.applyDecision(decision)
                        viewModel.popTopCard()

                        // 在卡片更新後確保按鈕狀態重置
                        DispatchQueue.main.async {
                            onSwipeDirectionChange(nil)
                        }

                        preloadNextCards()

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isAnimating = false
                        }
                    },
                    onCancel: {
                        cardOffsets[cardId] = .zero
                        onSwipeDirectionChange(nil)
                    }
                )
                .allowsHitTesting(isTop && !isAnimating)
                .zIndex(Double(config.visibleTopCount - idx))
            }
        }
    }
}

// MARK: - Private Helpers

private extension SwipeReviewDeck {
    func preloadNextCards() {
        let nextCards = Array(viewModel.deck.prefix(5))
        let targetSize = CGSize(width: 400, height: 600)
        photoLibraryService.preloadImages(for: nextCards, targetSize: targetSize)
    }
}

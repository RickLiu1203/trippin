//
//  AnimationPaper.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

extension Animation {
    static let paperSpring = Animation.spring(response: 0.3, dampingFraction: 0.8)
    static let paperEase = Animation.easeInOut(duration: 0.2)
}

struct PaperAnimationModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation
    let value: V

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? .none : animation, value: value)
    }
}

extension View {
    func paperAnimation<V: Equatable>(_ animation: Animation = .paperEase, value: V) -> some View {
        modifier(PaperAnimationModifier(animation: animation, value: value))
    }
}

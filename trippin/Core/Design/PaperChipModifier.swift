//
//  PaperChipModifier.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct PaperChipModifier: ViewModifier {
    var foreground: Color = .paperPrimary
    var background: Color = .clear
    var bordered: Bool = true

    func body(content: Content) -> some View {
        content
            .font(.paperBody(14, weight: .medium))
            .foregroundStyle(foreground)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(background)
            .clipShape(Capsule())
            .overlay(
                bordered ? Capsule().stroke(foreground, lineWidth: 1) : nil
            )
    }
}

extension View {
    func paperChip(
        foreground: Color = .paperPrimary,
        background: Color = .clear,
        bordered: Bool = true
    ) -> some View {
        modifier(PaperChipModifier(foreground: foreground, background: background, bordered: bordered))
    }
}

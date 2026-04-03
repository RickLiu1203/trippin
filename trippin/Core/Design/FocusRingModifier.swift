//
//  FocusRingModifier.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct FocusRingModifier: ViewModifier {
    let isFocused: Bool
    var cornerRadius: CGFloat = CornerRadius.md

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.paperPrimary, lineWidth: 2)
                    .padding(-2)
                    .opacity(isFocused ? 1 : 0)
            )
    }
}

extension View {
    func paperFocusRing(isFocused: Bool, cornerRadius: CGFloat = CornerRadius.md) -> some View {
        modifier(FocusRingModifier(isFocused: isFocused, cornerRadius: cornerRadius))
    }
}

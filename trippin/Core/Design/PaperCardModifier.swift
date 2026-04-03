//
//  PaperCardModifier.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct PaperCardModifier: ViewModifier {
    var padding: CGFloat = Spacing.md
    var elevated: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.paperSurface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(Color.paperBorder, lineWidth: 1)
            )
            .shadow(
                color: elevated ? Elevation.shadowColor : .clear,
                radius: elevated ? Elevation.shadowRadius : 0,
                y: elevated ? Elevation.shadowY : 0
            )
    }
}

extension View {
    func paperCard(padding: CGFloat = Spacing.md, elevated: Bool = false) -> some View {
        modifier(PaperCardModifier(padding: padding, elevated: elevated))
    }
}

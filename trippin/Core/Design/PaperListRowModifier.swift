//
//  PaperListRowModifier.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct PaperListRowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowBackground(Color.paperSurface)
            .listRowSeparatorTint(Color.paperBorder)
            .listRowInsets(EdgeInsets(
                top: Spacing.sm,
                leading: Spacing.md,
                bottom: Spacing.sm,
                trailing: Spacing.md
            ))
    }
}

extension View {
    func paperListRow() -> some View {
        modifier(PaperListRowModifier())
    }
}

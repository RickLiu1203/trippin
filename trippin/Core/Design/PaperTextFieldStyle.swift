//
//  PaperTextFieldStyle.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct PaperTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.paperBody())
            .foregroundStyle(Color.paperText)
            .padding(Spacing.sm)
            .background(Color.paperSurface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(Color.paperBorder, lineWidth: 1)
            )
    }
}

extension TextFieldStyle where Self == PaperTextFieldStyle {
    static var paper: PaperTextFieldStyle { .init() }
}

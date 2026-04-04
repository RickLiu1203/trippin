//
//  TimelineConnector.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct TimelineConnector: View {
    var isTravelGap: Bool = false

    var body: some View {
        HStack(spacing: Spacing.sm) {
            VStack(spacing: 0) {
                if isTravelGap {
                    DashedLine()
                        .stroke(Color.paperTextSecondary.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .frame(width: 1, height: 24)
                } else {
                    Rectangle()
                        .fill(Color.paperBorder)
                        .frame(width: 1, height: 24)
                }
            }
            .frame(width: 20)

            if isTravelGap {
                Image(systemName: "car.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.paperTextSecondary.opacity(0.5))
            }

            Spacer()
        }
        .padding(.leading, Spacing.md)
    }
}

private struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

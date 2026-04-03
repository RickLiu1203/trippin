//
//  MemberAvatarStack.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct MemberAvatarStack: View {
    let members: [TripMember]
    var maxDisplay: Int = 5

    private var visibleMembers: [TripMember] {
        Array(members.prefix(maxDisplay))
    }

    private var overflowCount: Int {
        max(0, members.count - maxDisplay)
    }

    var body: some View {
        HStack(spacing: -Spacing.xs) {
            ForEach(visibleMembers) { member in
                Circle()
                    .fill(Color(hex: member.color))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(member.emoji)
                            .font(.system(size: 14))
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.paperSurface, lineWidth: 2)
                    )
            }

            if overflowCount > 0 {
                Circle()
                    .fill(Color.paperBorder)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text("+\(overflowCount)")
                            .font(.paperMono(12, weight: .medium))
                            .foregroundStyle(Color.paperText)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.paperSurface, lineWidth: 2)
                    )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(members.count) member\(members.count == 1 ? "" : "s")")
    }
}

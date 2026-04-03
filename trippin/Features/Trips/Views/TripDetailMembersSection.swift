//
//  TripDetailMembersSection.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct TripDetailMembersSection: View {
    let members: [TripMember]
    let isOwner: Bool
    let onRemove: (TripMember) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Members")
                    .font(.paperBody(14, weight: .medium))
                    .foregroundStyle(Color.paperTextSecondary)
                Spacer()
                Text("\(members.count)")
                    .font(.paperMono(14))
                    .foregroundStyle(Color.paperTextSecondary)
            }

            VStack(spacing: 0) {
                ForEach(Array(members.enumerated()), id: \.element.id) { index, member in
                    MemberRow(member: member, showRemove: isOwner && member.role != .owner) {
                        onRemove(member)
                    }
                    if index < members.count - 1 {
                        Divider()
                            .padding(.leading, Spacing.md + 40 + Spacing.sm)
                    }
                }
            }
            .paperCard(padding: 0)
        }
    }
}

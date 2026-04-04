//
//  EditTripScreen.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct EditTripScreen: View {
    @State private var viewModel: EditTripViewModel
    @Environment(\.dismiss) private var dismiss
    let onSave: () -> Void

    init(tripId: UUID, currentName: String, onSave: @escaping () -> Void) {
        _viewModel = State(initialValue: EditTripViewModel(
            tripId: tripId,
            currentName: currentName
        ))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Trip name")
                        .font(.paperBody(14, weight: .medium))
                        .foregroundStyle(Color.paperTextSecondary)

                    TextField("Trip name", text: $viewModel.name)
                        .textFieldStyle(.paper)
                        .submitLabel(.done)
                        .accessibilityLabel("Trip name")
                }

                Spacer()
            }
            .padding(Spacing.lg)
            .background(Color.paperSurface)
            .navigationTitle("Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if await viewModel.save() {
                                onSave()
                                dismiss()
                            }
                        }
                    }
                    .font(.paperBody(16, weight: .semibold))
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

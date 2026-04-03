//
//  CreateTripSheet.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct CreateTripSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @FocusState private var isNameFocused: Bool
    let onSave: (String) -> Void

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Trip name")
                        .font(.paperBody(14, weight: .medium))
                        .foregroundStyle(Color.paperTextSecondary)

                    TextField("Where are you going?", text: $name)
                        .textFieldStyle(.paper)
                        .focused($isNameFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            saveIfValid()
                        }
                        .accessibilityLabel("Trip name")
                        .accessibilityHint("Enter the name for your trip")
                }

                Spacer()
            }
            .padding(Spacing.lg)
            .background(Color.paperSurface)
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        saveIfValid()
                    }
                    .font(.paperBody(16, weight: .semibold))
                    .disabled(trimmedName.isEmpty)
                }
            }
            .onAppear {
                isNameFocused = true
            }
        }
        .presentationDetents([.medium])
    }

    private func saveIfValid() {
        guard !trimmedName.isEmpty else { return }
        onSave(trimmedName)
        dismiss()
    }
}

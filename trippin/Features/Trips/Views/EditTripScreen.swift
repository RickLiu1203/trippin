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

    init(tripId: UUID, currentName: String, albumIdentifier: String?, onSave: @escaping () -> Void) {
        _viewModel = State(initialValue: EditTripViewModel(
            tripId: tripId,
            currentName: currentName,
            albumIdentifier: albumIdentifier
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

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Album")
                        .font(.paperBody(14, weight: .medium))
                        .foregroundStyle(Color.paperTextSecondary)

                    Button {
                        viewModel.showLinkAlbumSheet = true
                    } label: {
                        HStack {
                            Image(systemName: viewModel.albumIdentifier != nil
                                  ? "photo.on.rectangle.angled"
                                  : "plus.circle")
                            Text(viewModel.albumIdentifier != nil
                                 ? "Change Album"
                                 : "Link Album")
                                .font(.paperBody(16, weight: .medium))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.paperBody(14))
                                .foregroundStyle(Color.paperTextSecondary)
                        }
                        .foregroundStyle(Color.paperSecondary)
                        .padding(Spacing.sm)
                        .background(Color.paperSurface)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.sm))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                .stroke(Color.paperBorder, lineWidth: 1)
                        )
                    }
                    .accessibilityLabel(viewModel.albumIdentifier != nil ? "Change album" : "Link album")
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
            .sheet(isPresented: $viewModel.showLinkAlbumSheet) {
                LinkAlbumSheet { albumId in
                    Task { await viewModel.linkAlbum(albumId) }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

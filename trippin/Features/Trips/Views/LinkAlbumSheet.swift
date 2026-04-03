//
//  LinkAlbumSheet.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct LinkAlbumSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = LinkAlbumViewModel()
    let onSelect: (String) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.albums.isEmpty {
                    EmptyStateView(
                        icon: "photo.on.rectangle.angled",
                        title: "No shared albums",
                        message: "Create a shared album in the Photos app, then come back to link it"
                    )
                } else {
                    albumList
                }
            }
            .background(Color.paperSurface)
            .navigationTitle("Link Album")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                await viewModel.loadAlbums()
            }
        }
    }

    private var albumList: some View {
        List(viewModel.albums) { album in
            Button {
                onSelect(album.id)
                dismiss()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(album.title)
                            .font(.paperBody(16, weight: .medium))
                            .foregroundStyle(Color.paperText)
                        Text("\(album.assetCount) photos")
                            .font(.paperBody(14))
                            .foregroundStyle(Color.paperTextSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.paperBody(14))
                        .foregroundStyle(Color.paperTextSecondary)
                }
                .padding(.vertical, Spacing.xxs)
            }
            .paperListRow()
            .accessibilityLabel("\(album.title), \(album.assetCount) photos")
            .accessibilityHint("Double tap to link this album")
        }
        .listStyle(.plain)
    }
}

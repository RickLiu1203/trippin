//
//  CreateTripSheet.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct CreateTripSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var albums: [SharedAlbum] = []
    @State private var isLoading = true
    let linkedAlbumIds: Set<String>
    let albumService: SharedAlbumService
    let onSelect: (SharedAlbum) -> Void

    init(
        linkedAlbumIds: Set<String>,
        albumService: SharedAlbumService? = nil,
        onSelect: @escaping (SharedAlbum) -> Void
    ) {
        self.linkedAlbumIds = linkedAlbumIds
        self.albumService = albumService ?? PhotoKitSharedAlbumService()
        self.onSelect = onSelect
    }

    private var availableAlbums: [SharedAlbum] {
        albums.filter { !linkedAlbumIds.contains($0.id) }
    }

    private var sharedAlbums: [SharedAlbum] {
        availableAlbums.filter(\.isShared)
    }

    private var regularAlbums: [SharedAlbum] {
        availableAlbums.filter { !$0.isShared }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if availableAlbums.isEmpty {
                    emptyState
                } else {
                    albumList
                }
            }
            .background(Color.paperSurface)
            .navigationTitle("New Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                albums = await albumService.fetchAlbums()
                isLoading = false
            }
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "photo.on.rectangle.angled",
            title: albums.isEmpty ? "No albums found" : "All albums linked",
            message: albums.isEmpty
                ? "Create an album in Photos to get started"
                : "All your albums are already linked to trips"
        )
    }

    private var albumList: some View {
        List {
            if !sharedAlbums.isEmpty {
                Section {
                    ForEach(sharedAlbums) { album in
                        albumRow(album)
                    }
                } header: {
                    Text("Shared Albums")
                        .font(.paperBody(12, weight: .medium))
                        .foregroundStyle(Color.paperTextSecondary)
                }
            }

            if !regularAlbums.isEmpty {
                Section {
                    ForEach(regularAlbums) { album in
                        albumRow(album)
                    }
                } header: {
                    Text("My Albums")
                        .font(.paperBody(12, weight: .medium))
                        .foregroundStyle(Color.paperTextSecondary)
                }
            }
        }
        .listStyle(.plain)
    }

    private func albumRow(_ album: SharedAlbum) -> some View {
        Button {
            onSelect(album)
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
        .accessibilityHint("Double tap to create a trip from this album")
    }
}

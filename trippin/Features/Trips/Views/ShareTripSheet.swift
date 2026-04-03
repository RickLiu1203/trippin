//
//  ShareTripSheet.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

struct ShareTripSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ShareTripViewModel

    init(shareCode: String) {
        _viewModel = State(initialValue: ShareTripViewModel(shareCode: shareCode))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    if let qrImage = viewModel.qrImage {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                            .accessibilityLabel("QR code for trip invite link")
                    }

                    VStack(spacing: Spacing.sm) {
                        Text(viewModel.shareURL.absoluteString)
                            .font(.paperMono(14))
                            .foregroundStyle(Color.paperText)
                            .multilineTextAlignment(.center)
                            .textSelection(.enabled)

                        Button {
                            viewModel.copyURL()
                        } label: {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: viewModel.copied ? "checkmark" : "doc.on.doc")
                                Text(viewModel.copied ? "Copied" : "Copy Link")
                            }
                        }
                        .buttonStyle(.paperSecondary)
                        .accessibilityLabel(viewModel.copied ? "Link copied" : "Copy invite link")
                    }
                    .paperCard()

                    ShareLink(item: viewModel.shareURL) {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.paperPrimary)
                    .accessibilityLabel("Share invite link")
                }
                .padding(Spacing.lg)
            }
            .background(Color.paperSurface)
            .navigationTitle("Share Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

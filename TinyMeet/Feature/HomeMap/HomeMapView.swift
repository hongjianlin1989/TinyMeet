//
//  ContentView.swift
//  TinyMeet
//
//  Created by Hongjian Lin on 3/25/26.
//

import CoreData
import CoreLocation
import MapKit
import SwiftUI

struct HomeMapView: View {
    @StateObject private var viewModel = HomeMapViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $viewModel.cameraPosition) {
                    UserAnnotation()

                    ForEach(viewModel.privateEvents) { event in
                        Annotation(event.title, coordinate: event.coordinate) {
                            privateEventAnnotation(event)
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapCompass()
                    MapPitchToggle()
                    MapUserLocationButton()
                }
                .ignoresSafeArea(edges: .bottom)

                permissionOverlay
            }
            .navigationTitle("home.navigation.title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("home.login.action") {
                        viewModel.loginTapped()
                    }
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .sheet(isPresented: $viewModel.isShowingLoginView) {
            LoginView()
        }
    }

    @ViewBuilder
    private var permissionOverlay: some View {
        if let overlay = viewModel.overlayState {
            overlayCard(
                titleKey: overlay.titleKey,
                messageKey: overlay.messageKey,
                buttonTitleKey: overlay.buttonTitleKey,
                action: overlay.buttonTitleKey == nil ? nil : { viewModel.requestLocationAccess() }
            )
        }
    }

    private func privateEventAnnotation(_ event: PrivateEventMapItem) -> some View {
        VStack(spacing: 6) {
            Image(systemName: event.symbolName)
                .font(.headline)
                .foregroundStyle(.white)
                .padding(10)
                .background(annotationColor(for: event.tintName))
                .clipShape(Circle())

            VStack(spacing: 2) {
                Text(event.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(event.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func annotationColor(for tintName: String) -> Color {
        switch tintName {
        case "mint":
            return TinyMeetTheme.mint
        case "orange":
            return TinyMeetTheme.peach
        default:
            return TinyMeetTheme.accent
        }
    }

    private func overlayCard(
        titleKey: LocalizedStringResource,
        messageKey: LocalizedStringResource,
        buttonTitleKey: LocalizedStringResource?,
        action: (() -> Void)?
    ) -> some View {
        VStack {
            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                Text(titleKey)
                    .font(.headline)

                Text(messageKey)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let buttonTitleKey, let action {
                    Button(action: action) {
                        Text(buttonTitleKey)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding()
        }
    }
}

#Preview {
    HomeMapView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

//
//  ContentView.swift
//  TinyMeet
//
//  Created by Hongjian Lin on 3/25/26.
//

import SwiftUI
import CoreData
import MapKit
import CoreLocation

struct HomeMapView: View {
    @StateObject private var viewModel = HomeMapViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $viewModel.cameraPosition) {
                    UserAnnotation()
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

    private func overlayCard(titleKey: LocalizedStringResource, messageKey: LocalizedStringResource, buttonTitleKey: LocalizedStringResource?, action: (() -> Void)?) -> some View {
        VStack {
            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                Text(titleKey)
                    .font(.headline)

                Text(messageKey)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let buttonTitleKey, let action {
                    Button(buttonTitleKey, action: action)
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

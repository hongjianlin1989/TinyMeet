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
    @State private var isPlaydateSelectionVisible = true

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    mapContent(for: geometry.size)
                    permissionOverlay
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("home.navigation.title")
            .safeAreaInset(edge: .top) {
                playdateSelectionPanel
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    AuthToolbarButton()
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }

    @ViewBuilder
    private func mapContent(for size: CGSize) -> some View {
        if size.width > 0, size.height > 0 {
            Map(position: $viewModel.cameraPosition) {
                UserAnnotation()

                if let event = viewModel.selectedPlaydateEvent {
                    Annotation(event.title, coordinate: event.coordinate) {
                        privateEventAnnotation(event)
                    }
                }

                ForEach(viewModel.selectedInterestedPeople) { person in
                    Annotation(person.name, coordinate: person.coordinate) {
                        interestedPersonAnnotation(person)
                    }
                }
            }
            .frame(width: size.width, height: size.height)
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapCompass()
                MapPitchToggle()
                MapUserLocationButton()
            }
            .ignoresSafeArea(edges: .bottom)
        } else {
            Color.clear
        }
    }

    @ViewBuilder
    private var playdateSelectionPanel: some View {
        if isPlaydateSelectionVisible == false {
            panelCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Playdate view hidden")
                            .font(.subheadline.weight(.semibold))

                        if let selectedPlaydate = viewModel.selectedPlaydate {
                            Text(selectedPlaydate.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Button {
                        isPlaydateSelectionVisible = true
                    } label: {
                        Label("Show", systemImage: "eye")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        } else if viewModel.isLoadingInterestedPlaydates && viewModel.interestedPlaydates.isEmpty {
            panelCard {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Loading interested playdates...")
                        .font(.subheadline)
                }
            }
        } else if let errorMessage = viewModel.interestedPlaydatesErrorMessage, viewModel.interestedPlaydates.isEmpty {
            panelCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Couldn’t load your interested playdates")
                        .font(.headline)

                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        } else if viewModel.interestedPlaydates.isEmpty {
            panelCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text("No interested playdates yet")
                        .font(.headline)

                    Text("Mark a private playdate as interested to see it on the map.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            panelCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Selected playdate")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button {
                            isPlaydateSelectionVisible = false
                        } label: {
                            Label("Hide", systemImage: "eye.slash")
                                .labelStyle(.titleAndIcon)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    Picker(
                        "Choose playdate",
                        selection: Binding(
                            get: { viewModel.selectedPlaydateID },
                            set: { newValue in
                                if let newValue {
                                    viewModel.selectPlaydate(newValue)
                                }
                            }
                        )
                    ) {
                        ForEach(viewModel.interestedPlaydates) { playdate in
                            Text(playdate.title)
                                .tag(Optional(playdate.id))
                        }
                    }
                    .pickerStyle(.menu)

                    if let selectedPlaydate = viewModel.selectedPlaydate {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedPlaydate.title)
                                .font(.headline)
                            Text(selectedPlaydate.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
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

    private func interestedPersonAnnotation(_ person: InterestedPersonLocation) -> some View {
        VStack(spacing: 4) {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundStyle(TinyMeetTheme.accent)
                .padding(6)
                .background(.ultraThinMaterial, in: Circle())

            Text(person.name)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial, in: Capsule())
        }
    }

    private func annotationColor(for tintName: String) -> Color {
        switch tintName {
        case "mint":
            return TinyMeetTheme.mint
        case "orange":
            return TinyMeetTheme.peach
        case "pink":
            return TinyMeetTheme.accent
        default:
            return TinyMeetTheme.accent
        }
    }

    private func panelCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .shadow(color: TinyMeetTheme.shadow, radius: 10, x: 0, y: 4)
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

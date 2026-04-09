//
//  MapViewModel.swift
//  LabEx9_MapKit
//
//  Created by Tanupreet Kaur on 2026-04-08.
//

import Foundation
import Combine
import MapKit
import CoreLocation
import SwiftUI

final class MapViewModel: NSObject, ObservableObject {
    @Published var points: [CLLocationCoordinate2D] = []

    weak var mapView: MKMapView?

    private let geocoder = CLGeocoder()
    private let removeThresholdMeters: CLLocationDistance = 3000 // tap within 3 km removes point

    func setMapView(_ mapView: MKMapView) {
        self.mapView = mapView
    }

    func handleTap(at coordinate: CLLocationCoordinate2D) {
        if let existingIndex = indexOfNearbyPoint(to: coordinate) {
            points.remove(at: existingIndex)
            redrawMap()
            return
        }

        guard points.count < 3 else { return }

        points.append(coordinate)
        redrawMap()
    }

    func clearAll() {
        points.removeAll()

        guard let mapView else { return }
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
    }

    private func indexOfNearbyPoint(to coordinate: CLLocationCoordinate2D) -> Int? {
        let tappedLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        for (index, point) in points.enumerated() {
            let existingLocation = CLLocation(latitude: point.latitude, longitude: point.longitude)
            let distance = tappedLocation.distance(from: existingLocation)

            if distance < removeThresholdMeters {
                return index
            }
        }

        return nil
    }

    func redrawMap() {
        guard let mapView else { return }

        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)

        addPointAnnotations()

        if points.count == 3 {
            drawTriangle()
            addDistanceLabels()
        }
    }

    private func addPointAnnotations() {
        guard let mapView else { return }

        for (index, coordinate) in points.enumerated() {
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "Point \(index + 1)"
            annotation.subtitle = "Loading address..."
            mapView.addAnnotation(annotation)

            reverseGeocode(annotation: annotation)
        }
    }

    private func reverseGeocode(annotation: MKPointAnnotation) {
        let location = CLLocation(
            latitude: annotation.coordinate.latitude,
            longitude: annotation.coordinate.longitude
        )

        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard error == nil, let placemark = placemarks?.first else {
                DispatchQueue.main.async {
                    annotation.subtitle = "Address unavailable"
                }
                return
            }

            let parts = [
                placemark.name,
                placemark.locality,
                placemark.administrativeArea,
                placemark.country
            ].compactMap { $0 }.filter { !$0.isEmpty }

            let addressText = parts.joined(separator: ", ")

            DispatchQueue.main.async {
                annotation.subtitle = addressText.isEmpty ? "Address unavailable" : addressText
            }
        }
    }

    private func drawTriangle() {
        guard let mapView, points.count == 3 else { return }

        let a = points[0]
        let b = points[1]
        let c = points[2]

        let ab = MKPolyline(coordinates: [a, b], count: 2)
        let bc = MKPolyline(coordinates: [b, c], count: 2)
        let ca = MKPolyline(coordinates: [c, a], count: 2)

        let triangle = MKPolygon(coordinates: [a, b, c], count: 3)

        mapView.addOverlay(triangle)
        mapView.addOverlays([ab, bc, ca])
    }

    private func addDistanceLabels() {
        guard points.count == 3 else { return }

        addDistanceLabel(from: points[0], to: points[1], label: "A-B")
        addDistanceLabel(from: points[1], to: points[2], label: "B-C")
        addDistanceLabel(from: points[2], to: points[0], label: "C-A")
    }

    private func addDistanceLabel(from start: CLLocationCoordinate2D,
                                  to end: CLLocationCoordinate2D,
                                  label: String) {
        guard let mapView else { return }

        let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)

        let distanceKm = startLocation.distance(from: endLocation) / 1000.0

        let midpoint = CLLocationCoordinate2D(
            latitude: (start.latitude + end.latitude) / 2.0,
            longitude: (start.longitude + end.longitude) / 2.0
        )

        let annotation = MKPointAnnotation()
        annotation.coordinate = midpoint
        annotation.title = label
        annotation.subtitle = String(format: "%.2f km", distanceKm)

        mapView.addAnnotation(annotation)
    }

    func showRouteGuidance() {
        guard let mapView, points.count == 3 else { return }

        // Remove current overlays and redraw triangle first
        mapView.removeOverlays(mapView.overlays)
        drawTriangle()

        let legs: [(CLLocationCoordinate2D, CLLocationCoordinate2D)] = [
            (points[0], points[1]),
            (points[1], points[2]),
            (points[2], points[0])
        ]

        for (sourceCoordinate, destinationCoordinate) in legs {
            let request = MKDirections.Request()

            let sourcePlacemark = MKPlacemark(coordinate: sourceCoordinate)
            let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)

            request.source = MKMapItem(placemark: sourcePlacemark)
            request.destination = MKMapItem(placemark: destinationPlacemark)
            request.transportType = .automobile

            let directions = MKDirections(request: request)

            directions.calculate { [weak self] response, error in
                guard let self,
                      error == nil,
                      let route = response?.routes.first
                else {
                    return
                }

                DispatchQueue.main.async {
                    self.mapView?.addOverlay(route.polyline)
                }
            }
        }
    }
}


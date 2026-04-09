//
//  MapViewRepresentable.swift
//  LabEx9_MapKit
//
//  Created by Tanupreet Kaur on 2026-04-08.
//

import Foundation
import Combine
import SwiftUI
import MapKit
import CoreLocation

struct MapViewRepresentable: UIViewRepresentable {
    @ObservedObject var viewModel: MapViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.mapType = .standard

        // Center on Ontario
        let ontarioCenter = CLLocationCoordinate2D(latitude: 44.5, longitude: -79.5)
        let region = MKCoordinateRegion(
            center: ontarioCenter,
            span: MKCoordinateSpan(latitudeDelta: 8.0, longitudeDelta: 8.0)
        )
        mapView.setRegion(region, animated: false)

        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleMapTap(_:))
        )
        mapView.addGestureRecognizer(tapGesture)

        viewModel.setMapView(mapView)

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        let viewModel: MapViewModel

        init(viewModel: MapViewModel) {
            self.viewModel = viewModel
        }

        @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }

            let tapPoint = gesture.location(in: mapView)
            let coordinate = mapView.convert(tapPoint, toCoordinateFrom: mapView)

            viewModel.handleTap(at: coordinate)
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polygon = overlay as? MKPolygon {
                let renderer = MKPolygonRenderer(polygon: polygon)
                renderer.fillColor = UIColor.red.withAlphaComponent(0.5)
                renderer.strokeColor = UIColor.clear
                return renderer
            }

            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)

                // Route lines have many points, triangle edges only have 2
                if polyline.pointCount > 2 {
                    renderer.strokeColor = UIColor.systemBlue
                    renderer.lineWidth = 4
                } else {
                    renderer.strokeColor = UIColor.green
                    renderer.lineWidth = 3
                }

                return renderer
            }

            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }

            let identifier = "MapAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            } else {
                annotationView?.annotation = annotation
            }

            annotationView?.canShowCallout = true

            let title = annotation.title ?? ""
            if title == "A-B" || title == "B-C" || title == "C-A" {
                annotationView?.markerTintColor = .orange
                annotationView?.glyphText = "📏"
            } else {
                annotationView?.markerTintColor = .red
                annotationView?.glyphText = "📍"
            }

            return annotationView
        }
    }
}

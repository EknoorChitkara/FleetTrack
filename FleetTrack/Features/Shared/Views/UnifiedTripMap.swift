//
//  UnifiedTripMap.swift
//  FleetTrack
//
//  Created for Fleet Manager Trip Map Integration
//

import SwiftUI
import MapKit

/// A pure map component that renders a trip route and vehicle location
/// Supports both Driver (local GPS) and Fleet Manager (remote tracking) use cases
struct UnifiedTripMap<Provider: TripLocationProvider>: UIViewRepresentable {
    let trip: Trip
    @ObservedObject var provider: Provider
    let routePolyline: MKPolyline?
    
    // Annotations
    private let pickupAnnotation = MKPointAnnotation()
    private let dropoffAnnotation = MKPointAnnotation()
    private let vehicleAnnotation = MKPointAnnotation()
    
    init(trip: Trip, provider: Provider, routePolyline: MKPolyline? = nil) {
        self.trip = trip
        self.provider = provider
        self.routePolyline = routePolyline
        
        setupStaticAnnotations()
    }
    
    private func setupStaticAnnotations() {
        if let startLat = trip.startLat, let startLong = trip.startLong {
            pickupAnnotation.coordinate = CLLocationCoordinate2D(latitude: startLat, longitude: startLong)
            pickupAnnotation.title = "Pickup"
        }
        
        if let endLat = trip.endLat, let endLong = trip.endLong {
            dropoffAnnotation.coordinate = CLLocationCoordinate2D(latitude: endLat, longitude: endLong)
            dropoffAnnotation.title = "Dropoff"
        }
        
        vehicleAnnotation.title = "Vehicle"
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsCompass = true
        mapView.showsScale = true
        
        // Add static annotations
        mapView.addAnnotations([pickupAnnotation, dropoffAnnotation])
        mapView.addAnnotation(vehicleAnnotation)
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update Vehicle Location
        if let location = provider.currentLocation {
            UIView.animate(withDuration: 1.0) {
                vehicleAnnotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                
                // Update heading if available
                if let heading = provider.heading {
                    let view = mapView.view(for: vehicleAnnotation) as? MKMarkerAnnotationView
                    view?.markerTintColor = .systemBlue
                    // Note: Rotating marker view requires more complex handling, keeping simple for now
                }
            }
        }
        
        // Update Route Polyline
        updatePolyline(mapView: mapView, context: context)
        
        // Auto-Zoom logic
        if !context.coordinator.hasInitialZoom {
            zoomToFit(mapView: mapView)
            context.coordinator.hasInitialZoom = true
        }
    }
    
    private func updatePolyline(mapView: MKMapView, context: Context) {
        // Remove old polyline if changed
        if let oldPolyline = context.coordinator.currentPolyline, oldPolyline !== routePolyline {
            mapView.removeOverlay(oldPolyline)
        }
        
        // Add new polyline
        if let polyline = routePolyline, mapView.overlays.isEmpty {
            mapView.addOverlay(polyline, level: .aboveRoads)
            context.coordinator.currentPolyline = polyline
        }
    }
    
    private func zoomToFit(mapView: MKMapView) {
        var zoomRect = MKMapRect.null
        
        // Include static points
        let annotations = [pickupAnnotation, dropoffAnnotation]
        for annotation in annotations {
            let point = MKMapPoint(annotation.coordinate)
            let pointRect = MKMapRect(x: point.x, y: point.y, width: 0.1, height: 0.1)
            zoomRect = zoomRect.union(pointRect)
        }
        
        // Include route if available
        if let polyline = routePolyline {
            zoomRect = zoomRect.union(polyline.boundingMapRect)
        }
        
        // Include vehicle if available
        if let location = provider.currentLocation {
             let point = MKMapPoint(CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
             let pointRect = MKMapRect(x: point.x, y: point.y, width: 0.1, height: 0.1)
             zoomRect = zoomRect.union(pointRect)
        }
        
        let padding = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
        mapView.setVisibleMapRect(zoomRect, edgePadding: padding, animated: true)
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: UnifiedTripMap
        var currentPolyline: MKPolyline?
        var hasInitialZoom = false
        
        init(_ parent: UnifiedTripMap) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 5
                renderer.lineCap = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            
            let identifier = "Pin"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if view == nil {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view?.canShowCallout = true
            } else {
                view?.annotation = annotation
            }
            
            switch annotation.title {
            case "Pickup":
                view?.markerTintColor = .systemGreen
                view?.glyphImage = UIImage(systemName: "shippingbox.fill")
                view?.displayPriority = .required
            case "Dropoff":
                view?.markerTintColor = .systemRed
                view?.glyphImage = UIImage(systemName: "flag.fill")
                view?.displayPriority = .required
            case "Vehicle":
                view?.markerTintColor = .systemBlue
                view?.glyphImage = UIImage(systemName: "car.fill")
                view?.displayPriority = .required
            default:
                break
            }
            
            return view
        }
    }
}

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
    let isOffRoute: Bool
    
    // Annotations
    private let pickupAnnotation = MKPointAnnotation()
    private let dropoffAnnotation = MKPointAnnotation()
    private let vehicleAnnotation = MKPointAnnotation()
    
    init(trip: Trip, provider: Provider, routePolyline: MKPolyline? = nil, isOffRoute: Bool = false) {
        self.trip = trip
        self.provider = provider
        self.routePolyline = routePolyline
        self.isOffRoute = isOffRoute
        
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
        // Check if color needs update
        let needsColorUpdate = context.coordinator.lastIsOffRoute != isOffRoute
        context.coordinator.lastIsOffRoute = isOffRoute
        
        // Remove old polyline if changed or color update needed
        if let oldPolyline = context.coordinator.currentPolyline {
             if oldPolyline !== routePolyline || needsColorUpdate {
                 mapView.removeOverlay(oldPolyline)
                 context.coordinator.currentPolyline = nil
             }
        }
        
        // Add new polyline
        if let polyline = routePolyline, context.coordinator.currentPolyline == nil {
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
        var lastIsOffRoute = false
        
        init(_ parent: UnifiedTripMap) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                // START EDIT: Dynamic Color
                renderer.strokeColor = parent.isOffRoute ? .systemRed : .systemBlue
                // END EDIT
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
                view?.accessibilityLabel = "Pickup Location: \(parent.trip.startAddress)"
            case "Dropoff":
                view?.markerTintColor = .systemRed
                view?.glyphImage = UIImage(systemName: "flag.fill")
                view?.displayPriority = .required
                view?.accessibilityLabel = "Dropoff Location: \(parent.trip.endAddress)"
            case "Vehicle":
                view?.markerTintColor = .systemBlue
                view?.glyphImage = UIImage(systemName: "car.fill")
                view?.displayPriority = .required
                view?.accessibilityLabel = "Current Vehicle Location"
            default:
                break
            }
            
            // Generic fallback if not caught by switch
            if view?.accessibilityLabel == nil {
                view?.accessibilityLabel = annotation.title ?? "Map Location"
            }
            
            return view
        }
    }
}

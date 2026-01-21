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
    let scoredRoutes: [ScoredRoute]
    @Binding var selectedRouteID: UUID?
    
    // Additional Routes
    let plannedPolyline: MKPolyline? // The static, scheduled path (Trip Start -> End)
    
    // Legacy support
    let routePolyline: MKPolyline?
    let isOffRoute: Bool
    
    // Annotations
    private let pickupAnnotation = MKPointAnnotation()
    private let dropoffAnnotation = MKPointAnnotation()
    private let vehicleAnnotation = MKPointAnnotation()
    
    init(trip: Trip, provider: Provider, scoredRoutes: [ScoredRoute] = [], selectedRouteID: Binding<UUID?> = .constant(nil), plannedPolyline: MKPolyline? = nil, routePolyline: MKPolyline? = nil, isOffRoute: Bool = false) {
        self.trip = trip
        self.provider = provider
        self.scoredRoutes = scoredRoutes
        self._selectedRouteID = selectedRouteID
        self.plannedPolyline = plannedPolyline
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
        
        vehicleAnnotation.title = "My Location"
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsUserLocation = true // Show system blue dot
        
        // Add static annotations
        mapView.addAnnotations([pickupAnnotation, dropoffAnnotation])
        mapView.addAnnotation(vehicleAnnotation)
        
        // Add Interaction
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
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
        
        // Update Route Polylines
        updatePolylines(mapView: mapView, context: context)
        
        // Auto-Zoom logic
        if !context.coordinator.hasInitialZoom {
            zoomToFit(mapView: mapView)
            context.coordinator.hasInitialZoom = true
        }
    }
    
    private func updatePolylines(mapView: MKMapView, context: Context) {
        // Clear all previous overlays (simple approach for now)
        // Optimization: diff check could be better but this ensures clean state
        let currentOverlays = mapView.overlays
        if !currentOverlays.isEmpty {
             mapView.removeOverlays(currentOverlays)
        }
        
        // 1. Add Planned Route (Static) - Bottom Layer
        if let planned = plannedPolyline {
            let polyline = PlannedPolyline(points: planned.points(), count: planned.pointCount)
            mapView.addOverlay(polyline, level: .aboveRoads)
        }
        
        // 2. Add Scored Routes (Dynamic) - Top Layer
        if !scoredRoutes.isEmpty {
            // Determine active route: Selected OR Recommended
            let activeID = selectedRouteID ?? scoredRoutes.first(where: { $0.isRecommended })?.id
            
            // Draw in order: Inactive first (bottom), Active last (top)
            let sortedRoutes = scoredRoutes.sorted { (a, b) in
                // If a is active, it should be last. If b is active, it should be last.
                if a.id == activeID { return false }
                if b.id == activeID { return true }
                return false
            }
            
            for route in sortedRoutes {
                let polyline = ScoredPolyline(points: route.polyline.points(), count: route.polyline.pointCount)
                polyline.id = route.id
                // Highlight if it's the active one (Selected or Recommended default)
                polyline.isPrimary = (route.id == activeID)
                
                mapView.addOverlay(polyline, level: .aboveRoads)
            }
        } else if let polyline = routePolyline {
            // Fallback to legacy single line
             let wrapper = ScoredPolyline(points: polyline.points(), count: polyline.pointCount)
             wrapper.isPrimary = true
             mapView.addOverlay(wrapper, level: .aboveRoads)
        }
    }
    
    // Subclasses for differentiation
    class ScoredPolyline: MKPolyline {
        var isPrimary: Bool = false
        var id: UUID?
    }
    
    class PlannedPolyline: MKPolyline {}
    
    private func zoomToFit(mapView: MKMapView) {
        var zoomRect = MKMapRect.null
        
        // Include static points
        let annotations = [pickupAnnotation, dropoffAnnotation]
        for annotation in annotations {
            let point = MKMapPoint(annotation.coordinate)
            let pointRect = MKMapRect(x: point.x, y: point.y, width: 0.1, height: 0.1)
            zoomRect = zoomRect.union(pointRect)
        }
        
        // Include planned route
        if let planned = plannedPolyline {
            zoomRect = zoomRect.union(planned.boundingMapRect)
        }
        
        // Include scored routes (only primary/recommended to keep zoom tight)
        if let primary = scoredRoutes.first(where: { $0.isRecommended }) {
            zoomRect = zoomRect.union(primary.polyline.boundingMapRect)
        } else if let polyline = routePolyline {
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
                
                if let _ = polyline as? PlannedPolyline {
                    // Static / Planned Route Style
                    renderer.strokeColor = .systemGray2
                    renderer.lineWidth = 4
                    renderer.lineDashPattern = [4, 6] // More spaced dash
                    renderer.alpha = 0.6
                    return renderer
                }
                
                // Dynamic / Scored Routes
                if let polyline = polyline as? ScoredPolyline {
                    let isPrimary = polyline.isPrimary
                    // Native Map Blue: R:0 G:122 B:255
                    let nativeBlue = UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0)
                    
                    renderer.strokeColor = isPrimary ? nativeBlue : nativeBlue.withAlphaComponent(0.4)
                    renderer.lineWidth = isPrimary ? 6 : 5
                    renderer.alpha = 1.0
                } else {
                    // Fallback
                    renderer.strokeColor = UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0)
                    renderer.lineWidth = 5
                }
                
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
                view?.accessibilityLabel = "Dropoff Location: \(parent.trip.endAddress ?? "")"
            case "My Location":
                view?.markerTintColor = .systemBlue
                view?.glyphImage = UIImage(systemName: "location.fill")
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
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: mapView)
            let tapCoordinate = mapView.convert(point, toCoordinateFrom: mapView)
            
            // Hit Test for Polylines
            // Find closest polyline within a threshold
            var closestRouteID: UUID?
            var minDistance: Double = Double.greatestFiniteMagnitude
            
            // Map Point for precise math
            let tapMapPoint = MKMapPoint(tapCoordinate)
            // Approx meters per map point at this zoom? complex.
            // Using logic: Check distance from point to polyline
            
            for overlay in mapView.overlays {
                guard let polyline = overlay as? ScoredPolyline, let id = polyline.id else { continue }
                
                // Simple distance check to bounding box first
                let rect = polyline.boundingMapRect
                if rect.contains(tapMapPoint) || true { // Skip optim for now, check all
                    let distance = distanceToPolyline(tapMapPoint, polyline: polyline)
                    if distance < minDistance {
                        minDistance = distance
                        closestRouteID = id
                    }
                }
            }
            
            // Threshold (arbitrary map point units, need tuning or reprojection)
            // A better way is using renderer:
            // But let's try a simple heuristic. If minDistance is "small enough".
            // For now, simply select the closest one regardless of threshold to ensure interaction works easily.
            // Optimization: Only update if changed
            
            if let id = closestRouteID {
                print("📍 Tapped Route: \(id)")
                withAnimation {
                    self.parent.selectedRouteID = id
                }
            }
        }
        
        // Helper to find distance from point to polyline
        private func distanceToPolyline(_ point: MKMapPoint, polyline: MKPolyline) -> Double {
            var minDesc: Double = Double.greatestFiniteMagnitude
            
            let pointCount = polyline.pointCount
            let points = polyline.points()
            
            for i in 0..<(pointCount - 1) {
                let p1 = points[i]
                let p2 = points[i+1]
                let d = distanceToSegment(point, p1, p2)
                if d < minDesc { minDesc = d }
            }
            return minDesc
        }
        
        private func distanceToSegment(_ p: MKMapPoint, _ p1: MKMapPoint, _ p2: MKMapPoint) -> Double {
            let x = p.x, y = p.y
            let x1 = p1.x, y1 = p1.y
            let x2 = p2.x, y2 = p2.y
            
            let A = x - x1
            let B = y - y1
            let C = x2 - x1
            let D = y2 - y1
            
            let dot = A * C + B * D
            let len_sq = C * C + D * D
            var param = -1.0
            
            if len_sq != 0 { // avoid division by 0
                param = dot / len_sq
            }
            
            var xx, yy: Double
            
            if param < 0 {
                xx = x1
                yy = y1
            } else if param > 1 {
                xx = x2
                yy = y2
            } else {
                xx = x1 + param * C
                yy = y1 + param * D
            }
            
            let dx = x - xx
            let dy = y - yy
            return sqrt(dx * dx + dy * dy)
        }
    }
}

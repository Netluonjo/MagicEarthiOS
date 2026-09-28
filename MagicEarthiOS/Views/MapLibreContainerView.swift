import SwiftUI
import CoreLocation
import MapLibre

struct MapLibreContainerView: UIViewRepresentable {
    @Binding var styleType: MapStyleType
    @Binding var is3DEnabled: Bool
    @Binding var routeCoordinates: [CLLocationCoordinate2D]
    @Binding var drawnCoordinates: [CLLocationCoordinate2D]
    @Binding var centerCoordinate: CLLocationCoordinate2D?
    var onCoordinateTapped: ((CLLocationCoordinate2D) -> Void)?
    var mapCoordinateConverter: ((CGPoint) -> CLLocationCoordinate2D?)?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MLNMapView {
        let mapView = MLNMapView(frame: .zero, styleURL: styleType.styleURL)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.delegate = context.coordinator
        
        // Initial center on Hanoi (Hoan Kiem Lake)
        let initialCenter = CLLocationCoordinate2D(latitude: 21.0285, longitude: 105.8542)
        mapView.setCenter(initialCenter, zoomLevel: 14.5, animated: false)
        
        // Enable user location
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .followWithHeading
        
        // Setup gestures
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        
        context.coordinator.mapView = mapView
        return mapView
    }
    
    func updateUIView(_ uiView: MLNMapView, context: Context) {
        context.coordinator.parent = self
        
        // Update Style URL if changed
        if uiView.styleURL != styleType.styleURL {
            uiView.styleURL = styleType.styleURL
        }
        
        // Update 3D Camera Pitch
        let targetPitch: CGFloat = is3DEnabled ? 55.0 : 0.0
        if abs(uiView.camera.pitch - targetPitch) > 1.0 {
            let camera = uiView.camera
            camera.pitch = targetPitch
            uiView.setCamera(camera, animated: true)
        }
        
        // Recenter if requested
        if let center = centerCoordinate {
            uiView.setCenter(center, animated: true)
            DispatchQueue.main.async {
                self.centerCoordinate = nil
            }
        }
        
        // Update Route Polylines
        context.coordinator.updatePolylines(on: uiView)
    }
    
    class Coordinator: NSObject, MLNMapViewDelegate {
        var parent: MapLibreContainerView
        weak var mapView: MLNMapView?
        private var routePolyline: MLNPolyline?
        private var drawnPolyline: MLNPolyline?
        
        init(_ parent: MapLibreContainerView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
            // Apply 3D Extrusion Building Layer if supported by vector source
            if let compositeSource = style.source(withIdentifier: "openmaptiles") {
                let buildingLayer = MLNFillExtrusionStyleLayer(identifier: "3d-buildings", source: compositeSource)
                buildingLayer.sourceLayerIdentifier = "building"
                buildingLayer.fillExtrusionHeight = NSExpression(format: "mgl_coalesce(render_height, 15)")
                buildingLayer.fillExtrusionBase = NSExpression(format: "mgl_coalesce(render_min_height, 0)")
                buildingLayer.fillExtrusionColor = NSExpression(forConstantValue: UIColor(white: 0.85, alpha: 0.8))
                buildingLayer.fillExtrusionOpacity = NSExpression(forConstantValue: 0.85)
                
                if style.layer(withIdentifier: "3d-buildings") == nil {
                    style.addLayer(buildingLayer)
                }
            }
            updatePolylines(on: mapView)
        }
        
        func updatePolylines(on mapView: MLNMapView) {
            // Remove existing overlays
            if let existing = routePolyline {
                mapView.removeAnnotation(existing)
                routePolyline = nil
            }
            if let existingDrawn = drawnPolyline {
                mapView.removeAnnotation(existingDrawn)
                drawnPolyline = nil
            }
            
            // Add Navigation / Snapped Route Polyline (Deep Blue / Cyan)
            if !parent.routeCoordinates.isEmpty {
                var coords = parent.routeCoordinates
                let polyline = MLNPolyline(coordinates: &coords, count: UInt(coords.count))
                polyline.title = "active_route"
                mapView.addAnnotation(polyline)
                self.routePolyline = polyline
            }
            
            // Add Drawn Polyline (Neon Lime)
            if !parent.drawnCoordinates.isEmpty {
                var drawnCoords = parent.drawnCoordinates
                let polyline = MLNPolyline(coordinates: &drawnCoords, count: UInt(drawnCoords.count))
                polyline.title = "drawn_route"
                mapView.addAnnotation(polyline)
                self.drawnPolyline = polyline
            }
        }
        
        func mapView(_ mapView: MLNMapView, strokeColorForShapeAnnotation annotation: MLNShape) -> UIColor {
            if annotation.title == "drawn_route" {
                return UIColor(red: 0.22, green: 1.0, blue: 0.08, alpha: 0.95) // Neon Lime
            }
            return UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 0.9) // Nav Blue
        }
        
        func mapView(_ mapView: MLNMapView, lineWidthForPolylineAnnotation annotation: MLNPolyline) -> CGFloat {
            if annotation.title == "drawn_route" {
                return 7.0
            }
            return 8.0
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = mapView else { return }
            let point = gesture.location(in: mapView)
            let coord = mapView.convert(point, toCoordinateFrom: mapView)
            parent.onCoordinateTapped?(coord)
        }
        
        func convertPointToCoordinate(_ point: CGPoint) -> CLLocationCoordinate2D? {
            return mapView?.convert(point, toCoordinateFrom: mapView)
        }
        
        func convertCoordinateToPoint(_ coord: CLLocationCoordinate2D) -> CGPoint? {
            return mapView?.convert(coord, toPointTo: mapView)
        }
    }
}

//
//  ViewController.swift
//  LocationManagerHW
//
//  Created by Максим Жуин on 18.03.2024.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {

    let manager = CLLocationManager()

    private lazy var map: MKMapView = {
        let map = MKMapView(frame: CGRect(x: 10, y: 70, width: view.frame.width - 30 , height: view.frame.height - 220))
        map.layer.cornerRadius = 8.0
        map.showsUserLocation = true
        map.delegate = self
        map.mapType = .mutedStandard
        map.layer.borderColor = UIColor.systemGray3.cgColor
        map.layer.borderWidth = 1.0
        let tapgest = UITapGestureRecognizer(target: self, action: #selector(setAnnotation(_:)))
        map.addGestureRecognizer(tapgest)
        return map
    }()

    private lazy var removeButton: UIButton = {
        let removeButton = UIButton(type: .system)
        removeButton.frame = CGRect(x: 120, y: 740, width: 140, height: 60)
        removeButton.backgroundColor = .white
        removeButton.layer.cornerRadius = 8.0
        removeButton.setTitle("Очистиить карту", for: .normal)
        removeButton.setTitleColor(.black, for: .normal)
        removeButton.layer.shadowColor = UIColor.systemGray5.cgColor
        removeButton.layer.shadowOffset = CGSize(width: 6, height: 6)
        removeButton.layer.shadowOpacity = 0.8
        removeButton.addTarget(self, action: #selector(removeAnnotations(_:)), for: .touchUpInside)
        return removeButton
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(map)
        view.addSubview(removeButton)
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        checkStatus()
    }

    func checkStatus() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self else { return }
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                let lat = manager.location?.coordinate.latitude
                let lon = manager.location?.coordinate.longitude
                let coordinate = CLLocationCoordinate2D(latitude: lat!, longitude: lon!)
                let regio = MKCoordinateRegion(center: coordinate, latitudinalMeters: 200, longitudinalMeters: 200)
                map.setRegion(regio, animated: true)
            case .denied, .notDetermined, .restricted:
                manager.stopUpdatingLocation()
            @unknown default:
                assertionFailure("Unknown error")
            }
        }
    }

    @objc func setAnnotation(_ sender: UITapGestureRecognizer) {

        let point = sender.location(in: map)
        let coordinate = map.convert(point, toCoordinateFrom: map)
        let placeMark = MKPlacemark(coordinate: coordinate)
        let destinationPoint = MKMapItem(placemark: placeMark)

        let destinationAnnotation = MapAnnotationPoint()
        destinationAnnotation.coordinate = destinationPoint.placemark.coordinate
        map.addAnnotation(destinationAnnotation)
    }

    func setRoute(to destintaion: MKMapItem) {
        let directionRequest = MKDirections.Request()
        directionRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: (manager.location?.coordinate)!))
        directionRequest.destination = destintaion
        directionRequest.transportType = .walking

        let directions = MKDirections(request: directionRequest)

        directions.calculate { [weak self] (response, error)  in
            guard let self else { return }
            guard let response = response else {
                if let error = error {
                    print("Error: \(error)")
                }

                return
            }

            let route = response.routes.first!
            map.addOverlay((route.polyline), level: MKOverlayLevel.aboveRoads)
        }
    }

    @objc func removeAnnotations(_ sender: UIButton) {
        let userLocation = map.userLocation
        let annotationsToRemove = map.annotations.filter { $0 !== userLocation }
        map.removeAnnotations(annotationsToRemove)
        map.removeOverlays(map.overlays)
    }

    func removeOverlay() {
        map.removeOverlay(map.overlays.last!)
    }

}

extension ViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
            map.setRegion(MKCoordinateRegion(center: (manager.location?.coordinate)!, latitudinalMeters: 100, longitudinalMeters: 100), animated: true)
        case .denied, .notDetermined, .restricted:
            manager.stopUpdatingLocation()
        @unknown default:
            assertionFailure("Unknown error")
        }
    }
}

extension ViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        let renderer = MKPolylineRenderer(overlay: overlay)

        renderer.strokeColor = .systemBlue

        renderer.lineWidth = 2.0

        return renderer
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
                return nil
            }
        let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "customAnnotation")
            annotationView.glyphImage = UIImage(systemName: "circle.circle")
            annotationView.markerTintColor = .blue
            annotationView.canShowCallout = true

            return annotationView
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let _ = view.annotation {
            let uiAert = UIAlertController(title: "", message: "Проложить маршрут?", preferredStyle: .actionSheet)
            let action = UIAlertAction(title: "Пешком", style: .default) { [weak self] _ in
                guard let self else { return }
                setRoute(to: MKMapItem(placemark: MKPlacemark(coordinate: (view.annotation?.coordinate)!)))
                if !map.overlays.isEmpty {
                    removeOverlay()
                }
            }
            uiAert.addAction(action)
            present(uiAert, animated: true)
        }
    }
}

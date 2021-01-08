//
//  MapController.swift
//  MapKitDemo
//
//  Created by Alexander Ha on 1/4/21.
//

import UIKit
import MapKit
import CoreLocation

class MapController: UIViewController {
    
    //MARK: - UIComponents
    
    private var searchInputView: SearchInputView!
    
    private let centerLocationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "location.viewfinder"), for: .normal)
        button.tintColor = #colorLiteral(red: 0.3020650255, green: 0.6180910299, blue: 0.9686274529, alpha: 1)
        button.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        button.layer.cornerRadius = 13
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowRadius = 1
        button.layer.shadowOffset = CGSize(width: 3, height: 3)
        button.layer.shadowOpacity = 0.3
        button.imageView?.setDimensions(height: 40, width: 45)
        button.addTarget(self, action: #selector(handleCenterLocation), for: .touchUpInside)
        return button
    }()
    
    //MARK: - Properties
    
    private var mapView: MKMapView!
    private var locationManager: CLLocationManager!
    private var route: MKRoute?
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        enableLocationServices()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        centerMapOnUserLocation(shouldLoadAnnotations: true)
    }
    
    //MARK: - Selectors
    
    @objc func handleCenterLocation() {
        centerMapOnUserLocation(shouldLoadAnnotations: false)
    }
    
    //MARK: - Helper Functions
    
    private func configureUI() {
        view.backgroundColor = .white
        configureMapView()
        
        view.addSubview(centerLocationButton)
        centerLocationButton.anchor(top: view.topAnchor, trailing: view.trailingAnchor, paddingTop: 88, paddingTrailing: 16, height: 50, width: 50)
        
        searchInputView = SearchInputView()
        searchInputView.delegate = self
        searchInputView.mapController = self
        
        view.addSubview(searchInputView)
        searchInputView.anchor(leading: view.leadingAnchor,
                               bottom: view.bottomAnchor,
                               trailing: view.trailingAnchor,
                               paddingBottom: -(view.frame.height - 88),
                               height: view.frame.height)
    }
    
    private func configureMapView() {
        mapView = MKMapView()
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
        view.addSubview(mapView)
        mapView.addConstraintsToFillView(view: view)
    }
}


//MARK: - MapKit Helper Functions

extension MapController {
    
    func zoomToFit(selectedAnnotation: MKAnnotation?) {
        if mapView.annotations.count == 0 {
            return
        }
        //top left and bottom right coordinate needed to implement zoom functionality
        var topLeftCoordinate = CLLocationCoordinate2D(latitude: -90, longitude: 180)
        var bottomRightCoordinate = CLLocationCoordinate2D(latitude: 90, longitude: -180)
        
        if let selectedAnnotation = selectedAnnotation {
            for annotation in mapView.annotations {
                if let userAnnotation = annotation as? MKUserLocation {
                    topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, userAnnotation.coordinate.longitude)
                    topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, userAnnotation.coordinate.latitude)
                    bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, userAnnotation.coordinate.longitude)
                    bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, userAnnotation.coordinate.latitude)
                }
                if annotation.title == selectedAnnotation.title {
                    topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
                    topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
                    bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
                    bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
                }
            }
            var region = MKCoordinateRegion(center: CLLocationCoordinate2DMake(topLeftCoordinate.latitude - (topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * 0.65, topLeftCoordinate.longitude + (bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 0.65), span: MKCoordinateSpan(latitudeDelta: fabs(topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * 3.0, longitudeDelta: fabs(bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 3.0))
            
            region = mapView.regionThatFits(region)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func generatePolyline(forDestinationMapItem destinationMapItem: MKMapItem) {
        
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = destinationMapItem
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { (response, error) in
            guard let response = response else { return }
            self.route = response.routes[0]
            guard let polyline = self.route?.polyline else { return }
            self.mapView.addOverlay(polyline)
        }
    }
    
    func searchBy(naturalLanguageQuery: String, region: MKCoordinateRegion, coordinates: CLLocationCoordinate2D, completion: @escaping (_ response: MKLocalSearch.Response?, _ error: NSError?) -> ()) {
        
        //creating local search request
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = naturalLanguageQuery
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            guard let response = response else {
                completion(nil, error! as NSError)
                return
            }
            completion(response, nil)
        }
    }
    
    func centerMapOnUserLocation(shouldLoadAnnotations: Bool) {
        //need coordinates and region
        guard let coordinates = locationManager.location?.coordinate else { return }
        let coordinateRegion = MKCoordinateRegion(center: coordinates, latitudinalMeters: 2000, longitudinalMeters: 2000)
        mapView.setRegion(coordinateRegion, animated: true)
        
        if shouldLoadAnnotations {
            loadAnnotations(withSearchQuery: "restaurants")
        }
        searchInputView.expansionState = .NotExpanded
    }
    
    func removeAnnotations() {
        mapView.annotations.forEach { annotation in
            if let annotation = annotation as? MKPointAnnotation {
                mapView.removeAnnotation(annotation)
            }
        }
    }
    
    func loadAnnotations(withSearchQuery query: String) {
        guard let coordinate = locationManager.location?.coordinate else { return }
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
        
        searchBy(naturalLanguageQuery: query, region: region, coordinates: coordinate) { (response, error) in
            
            guard let response = response else { return }
            
            response.mapItems.forEach({ mapItem in
                let annotation = MKPointAnnotation()
                annotation.title = mapItem.name
                annotation.coordinate = mapItem.placemark.coordinate
                self.mapView.addAnnotation(annotation)
            })
            self.searchInputView.searchResults = response.mapItems
        }
    }
    
}

//MARK: - MKMapViewDelegate

extension MapController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let route = self.route {
            let polyline = route.polyline
            let lineRenderer = MKPolylineRenderer(overlay: polyline)
            lineRenderer.strokeColor = .systemBlue
            lineRenderer.lineWidth = 3
            return lineRenderer
        }
        return MKOverlayRenderer()
    }
    
}

//MARK: - CLLocationManagerDelegate

extension MapController: CLLocationManagerDelegate {
    
    func enableLocationServices() {
        let locationVC = LocationRequestController()
        locationVC.modalPresentationStyle = .fullScreen
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            print("not determined")
            DispatchQueue.main.async {
                locationVC.locationManager = self.locationManager
                self.present(locationVC, animated: true, completion: nil)
            }
        case .restricted:
            print("restricted")
        case .denied:
            print("denied")
        case .authorizedAlways:
            print("always authorized")
        case .authorizedWhenInUse:
            print("only when in use")
        @unknown default:
            print("unknown case")
        }
    }
}

//MARK: - SearchInputViewDelegate

extension MapController: SearchInputViewDelegate {
    
    func selectAnnotation(withMapItem mapItem: MKMapItem) {
        mapView.annotations.forEach { annotation in
            if annotation.title == mapItem.name {
                self.mapView.selectAnnotation(annotation, animated: true)
                self.zoomToFit(selectedAnnotation: annotation)
            } else if annotation.title != mapItem.name {
                self.mapView.removeAnnotation(annotation)
            }
        }
    }
    
    func addPolyline(forDestinationMapItem destinationMapItem: MKMapItem) {
        generatePolyline(forDestinationMapItem: destinationMapItem)
    }
    
    func handleSearch(withSearchText searchText: String) {
        if mapView.overlays.count > 0 {
            self.mapView.removeOverlay(mapView.overlays[0])
        }
        centerMapOnUserLocation(shouldLoadAnnotations: false)
        removeAnnotations()
        loadAnnotations(withSearchQuery: searchText)
    }
}

//MARK: - SearchCellDelegate

extension MapController: SearchCellDelegate {
    
    func getDirections(forMapItem mapItem: MKMapItem) {
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
    }
    
    func distanceFromUser(location: CLLocation) -> CLLocationDistance? {
        //grabbing user location
        guard let userLocation = locationManager.location else { return nil}
        return userLocation.distance(from: location)
    }
}


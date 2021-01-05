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
    
    //MARK: - Properties
    
    private var mapView: MKMapView!
    private var locationManager: CLLocationManager!
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        enableLocationServices()
    }
    
    
    //MARK: - Helper Functions
 
    private func configureUI() {
        view.backgroundColor = .white
        configureMapView()
    }
    
    private func configureMapView() {
        mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
        view.addSubview(mapView)
        mapView.addConstraintsToFillView(view: view)
    }
    
}

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

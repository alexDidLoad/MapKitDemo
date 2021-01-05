//
//  LocationRequestController.swift
//  MapKitDemo
//
//  Created by Alexander Ha on 1/4/21.
//

import UIKit
import CoreLocation

class LocationRequestController: UIViewController {
    
    //MARK: - UIComponents
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "blue-pin")
        return iv
    }()
    
    private let allowLocationLabel: UILabel = {
        let label = UILabel()
        let attributedText = NSMutableAttributedString(string: "Allow Location\n", attributes: [NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 24)])
        attributedText.append(NSAttributedString(string: "Please enable location services in order to use the app", attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16)]))
        label.numberOfLines = 0
        label.textAlignment = .center
        label.attributedText = attributedText
        return label
    }()
    
    private let enableLocationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Enable Location", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.backgroundColor = #colorLiteral(red: 0.2190384696, green: 0.5660907721, blue: 1, alpha: 1)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(handleRequestLocation), for: .touchUpInside)
        return button
    }()
    
    //MARK: - Properties
    
    var locationManager: CLLocationManager?
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
       
    }
    
    //MARK: - Selectors
    
    @objc func handleRequestLocation() {
        guard let locationManager = self.locationManager else { return }
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    //MARK: - Helper Functions
    
    private func configureUI() {
        view.backgroundColor = .white
        
        view.addSubview(imageView)
        imageView.anchor(top: view.topAnchor, paddingTop: 140, height: 200, width: 200)
        imageView.centerX(inView: view)
        
        view.addSubview(allowLocationLabel)
        allowLocationLabel.anchor(top: imageView.bottomAnchor, leading: view.leadingAnchor, trailing: view.trailingAnchor, paddingTop: 32, paddingLeading: 32, paddingTrailing: 32)
        allowLocationLabel.centerX(inView: view)
        
        view.addSubview(enableLocationButton)
        enableLocationButton.anchor(top: allowLocationLabel.bottomAnchor, paddingTop: 24, height: 50, width: 250)
        enableLocationButton.centerX(inView: view)
    }
    
}

extension LocationRequestController: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard locationManager?.location != nil else { return }
        
        dismiss(animated: true, completion: nil)
    }
    
}

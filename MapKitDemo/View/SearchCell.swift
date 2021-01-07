//
//  SearchCell.swift
//  MapKitDemo
//
//  Created by Alexander Ha on 1/4/21.
//

import UIKit
import MapKit

protocol SearchCellDelegate {
    func distanceFromUser(location: CLLocation) -> CLLocationDistance?
    func getDirections(forMapItem: MKMapItem)
}

class SearchCell: UITableViewCell {
    
    //MARK: - UIComponents
    
    private lazy var imageContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.addSubview(locationImageView)
        locationImageView.center(inView: view)
        locationImageView.setDimensions(height: 42, width: 42)
        return view
    }()
    
    private let locationImageView: UIImageView = {
        let iv = UIImageView()
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(systemName: "mappin.circle.fill")
        iv.tintColor = .systemRed
        return iv
    }()
    
    private let locationTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        return label
    }()
    
    private let locationDistanceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .lightGray
        return label
    }()
    
    private lazy var goButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "car.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1)
        button.layer.cornerRadius = 5
        button.alpha = 0
        button.addTarget(self, action: #selector(handleGo), for: .touchUpInside)
        return button
    }()
    
    //MARK: - Properties
    
    var delegate: SearchCellDelegate?
    var mapItem: MKMapItem? {
        didSet {
            configureCellLabel()
        }
    }
    
    //MARK: - Lifecycle
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        configureTableCellUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Selectors
    
    @objc func handleGo() {
        guard let mapItem = self.mapItem else { return }
        delegate?.getDirections(forMapItem: mapItem)
    }
    
    //MARK: - Helpers
    
    func animateButtonIn() {
        goButton.transform = CGAffineTransform(scaleX: 0.25, y: 0.25)
        UIView.animate(withDuration: 0.9, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseInOut) {
            self.goButton.transform = .identity
            self.goButton.alpha = 1
        }
    }
    
    private func configureTableCellUI() {
        let dimensions: CGFloat = 36
        self.selectionStyle = .none
        
        goButton.setDimensions(height: 50, width: 50)
        contentView.addSubview(goButton)
        goButton.anchor(trailing: trailingAnchor, paddingTrailing: 8)
        goButton.centerY(inView: self)
        
        addSubview(imageContainerView)
        imageContainerView.anchor(leading: leadingAnchor, paddingLeading: 10)
        imageContainerView.setDimensions(height: dimensions, width: dimensions)
        imageContainerView.layer.cornerRadius = dimensions / 2
        imageContainerView.centerY(inView: self)
        
        addSubview(locationTitleLabel)
        locationTitleLabel.anchor(top: imageContainerView.topAnchor, leading: imageContainerView.trailingAnchor, paddingLeading: 8)
        
        addSubview(locationDistanceLabel)
        locationDistanceLabel.anchor(top: locationTitleLabel.bottomAnchor, leading: imageContainerView.trailingAnchor, paddingTop: 8, paddingLeading: 8)
    }
    
    private func configureCellLabel() {
        locationTitleLabel.text = mapItem?.name
        
        let distanceFormatter = MKDistanceFormatter()
        distanceFormatter.unitStyle = .abbreviated
        guard let mapItemLocation = mapItem?.placemark.location else { return }
        guard let distanceFromUser = delegate?.distanceFromUser(location: mapItemLocation) else { return }
        let distanceAsString = distanceFormatter.string(fromDistance: distanceFromUser)
        locationDistanceLabel.text = distanceAsString
    }
    
}

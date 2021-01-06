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
    
    //MARK: - Helpers
    
    private func configureTableCellUI() {
        let dimensions: CGFloat = 36
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

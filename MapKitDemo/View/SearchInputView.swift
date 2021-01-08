//
//  SearchInputView.swift
//  MapKitDemo
//
//  Created by Alexander Ha on 1/4/21.
//

import UIKit
import MapKit

private let reuseIdentifier = "SearchCell"

protocol SearchInputViewDelegate {
    func handleSearch(withSearchText searchText: String)
    func addPolyline(forDestinationMapItem destinationMapItem: MKMapItem)
    func selectAnnotation(withMapItem mapItem: MKMapItem)
}

class SearchInputView: UIView {
    
    //MARK: - UIComponents
    
    private let indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        view.layer.cornerRadius = 5
        view.alpha = 0.8
        return view
    }()
    
    private var searchBar: UISearchBar!
    private var tableView: UITableView!
    
    //MARK: - Properties
    
    enum ExpansionState {
        case NotExpanded
        case PartiallyExpanded
        case FullyExpanded
        case ExpandToSearch
    }
    
    var mapController: MapController?
    var expansionState: ExpansionState!
    var delegate: SearchInputViewDelegate?
    var searchResults: [MKMapItem]? {
        didSet {
            tableView.reloadData()
        }
    }
    
    //MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
        expansionState = .NotExpanded
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Selectors
    
    @objc func handleSwipeGesture(sender: UISwipeGestureRecognizer) {
        
        if sender.direction == .up {
            
            if expansionState == .NotExpanded {
                animateInputView(targetPosition: self.frame.origin.y - 250) { (_) in
                    self.expansionState = .PartiallyExpanded
                }
            }
            
            if expansionState == .PartiallyExpanded {
                animateInputView(targetPosition: self.frame.origin.y - 460) { (_) in
                    self.expansionState = .FullyExpanded
                }
            }
            
        } else if sender.direction == .down {
            
            if expansionState == .FullyExpanded {
                animateInputView(targetPosition: self.frame.origin.y + 460) { (_) in
                    self.expansionState = .PartiallyExpanded
                }
            }
            
            if expansionState == .PartiallyExpanded {
                animateInputView(targetPosition: self.frame.origin.y + 250) { (_) in
                    self.expansionState = .NotExpanded
                }
            }
            searchBar.showsCancelButton = false
            searchBar.endEditing(true)
        }
        
    }
    
    //MARK: - Helpers
    
    private func didSelectMapItem(withMapItems items: [MKMapItem], selectedMapItem: MKMapItem, atIndexPath indexPath: IndexPath) -> [MKMapItem] {
        var items = items
        items.remove(at: indexPath.row)
        items.insert(selectedMapItem, at: 0)
        items.removeSubrange(1..<items.count)
        return items
    }
    
    private func dismissOnSearch() {
        searchBar.showsCancelButton = false
        searchBar.endEditing(true)
        
        animateInputView(targetPosition: self.frame.origin.y + 460) { (_) in
            self.expansionState = .PartiallyExpanded
        }
    }
    
    private func configureUI() {
        backgroundColor = .white
        
        addSubview(indicatorView)
        indicatorView.anchor(top: topAnchor, paddingTop: 8, height: 8, width: 80)
        indicatorView.centerX(inView: self)
        
        configureSearchBar()
        configureTableView()
        configureGestureRecognizer()
    }
    
    private func configureSearchBar() {
        searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.placeholder = "Search for a place or address"
        searchBar.barStyle = .default
        searchBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        
        addSubview(searchBar)
        searchBar.anchor(top: indicatorView.bottomAnchor, leading: leadingAnchor, trailing: trailingAnchor , paddingTop: 4, paddingLeading: 8, paddingTrailing: 8, height: 50)
    }
    
    private func configureTableView() {
        tableView = UITableView()
        tableView.rowHeight = 72
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(SearchCell.self, forCellReuseIdentifier: reuseIdentifier)
        addSubview(tableView)
        tableView.anchor(top: searchBar.bottomAnchor, leading: leadingAnchor, bottom: bottomAnchor, trailing: trailingAnchor, paddingTop: 8, paddingBottom: 100)
    }
    
    private func configureGestureRecognizer() {
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture))
        swipeUp.direction = .up
        addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture))
        swipeDown.direction = .down
        addGestureRecognizer(swipeDown)
    }
    
    private func animateInputView(targetPosition: CGFloat, completion: @escaping(Bool) -> ()) {
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            //changes y position of view
            self.frame.origin.y = targetPosition
        }, completion: completion)
    }
    
}

//MARK: - UITableViewDelegate and UITableViewDataSource

extension SearchInputView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let searchResults = searchResults else { return 0 }
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! SearchCell
        
        if let controller = mapController {
            cell.delegate = controller
        }
        if let searchResults = searchResults {
            cell.mapItem = searchResults[indexPath.row]
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let searchResults = searchResults else { return }
        let selectedMapItem = searchResults[indexPath.row]
        
        delegate?.selectAnnotation(withMapItem: selectedMapItem)
        delegate?.addPolyline(forDestinationMapItem: selectedMapItem)
        
        // FIXME: Refactor
        if expansionState == .FullyExpanded {
            self.searchBar.endEditing(true)
            self.searchBar.showsCancelButton = false
            animateInputView(targetPosition: self.frame.origin.y + 460) { (_) in
                self.expansionState = .PartiallyExpanded
            }
        }
        self.searchResults = didSelectMapItem(withMapItems: searchResults, selectedMapItem: selectedMapItem, atIndexPath: indexPath)
        
        let firstIndexPath = IndexPath(row: 0, section: 0)
        let cell = tableView.cellForRow(at: firstIndexPath) as? SearchCell
        cell?.animateButtonIn()
    }
    
}

//MARK: - UISearchBarDelegate

extension SearchInputView: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text else { return }
        delegate?.handleSearch(withSearchText: searchText)
        dismissOnSearch()
        
        let firstIndexPath = IndexPath(row: 0, section: 0)
        let cell = tableView.cellForRow(at: firstIndexPath) as? SearchCell
        cell?.removeButton()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
        
        if expansionState == .NotExpanded {
            animateInputView(targetPosition: self.frame.origin.y - 710) { (_) in
                self.expansionState = .FullyExpanded
            }
        }
        
        if expansionState == .PartiallyExpanded {
            animateInputView(targetPosition: self.frame.origin.y - 460) { (_) in
                self.expansionState = .FullyExpanded
            }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dismissOnSearch()
    }
}


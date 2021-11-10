//
//  PokemonsViewController.swift
//  VIPPokemon
//
//  Created by Marlon David Ruiz Arroyave on 9/11/21.
//  Copyright (c) 2021 ___ORGANIZATIONNAME___. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit
import SVProgressHUD

protocol PokemonsDisplayLogic: AnyObject {
    func displayFetchedPokemons(viewModel: Pokemons.FetchPokemons.ViewModel)
}

class PokemonsViewController: UICollectionViewController {

    // MARK: Properties

    var interactor: PokemonsBusinessLogic?
    var router: (NSObjectProtocol & PokemonsRoutingLogic & PokemonsDataPassing)?

    private var displayedPokemons: [Pokemons.FetchPokemons.ViewModel.DisplayedPokemon] = []
    private var resultPokemons: [Pokemons.FetchPokemons.ViewModel.DisplayedPokemon] = []
    
    private var latestSearch: String? {
        UserDefaults.standard.string(forKey: .searchText)
    }
    
    lazy private var searchController: SearchBar = {
        let searchController = SearchBar("Search a pokemon", delegate: self)
        searchController.text = latestSearch
        searchController.showsCancelButton = !searchController.isSearchBarEmpty
        return searchController
    }()
    
    private var isFirstLauch: Bool = true
    
    private var shouldShowLoader: Bool = false {
        didSet {
            if shouldShowLoader {
                SVProgressHUD.shouldShowLoader(isFirstLauch)
            } else {
                isFirstLauch = false
                SVProgressHUD.shouldShowLoader(false)
            }
        }
    }

    // MARK: Object lifecycle

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    // MARK: Setup
    
    private func setup() {
        PokemonsConfigurator.configureModule(viewController: self)
    }
    
    // MARK: Routing
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let scene = segue.identifier {
            let selector = NSSelectorFromString("routeTo\(scene)WithSegue:")
            if let router = router, router.responds(to: selector) {
                router.perform(selector, with: segue)
            }
        }
    }
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        refresh()
    }

    // MARK: - Public Methods
    
    @objc func refresh() {
        shouldShowLoader = true
        let request = Pokemons.FetchPokemons.Request()
        interactor?.fetchPokemons(request: request)
    }
    
    // // MARK: - Private Methods
    
    private func didRefresh() {
        shouldShowLoader = false
        
        guard
            let collectionView = collectionView,
            let refreshControl = collectionView.refreshControl
        else { return }
        
        refreshControl.endRefreshing()
        
        updateSearchResults(for: searchController.text ??  "")
    }

    private func setupUI() {

        // Set up the collection view.
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .white
        collectionView.alwaysBounceVertical = true
        collectionView.indicatorStyle = .white

        // Set up the refresh control as part of the collection view when it's pulled to refresh.
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        collectionView.sendSubviewToBack(refreshControl)

        setupNavBar()
    }

    private func setupNavBar() {
        title = "Pokédex"

        // Customize navigation bar.
        guard let navbar = self.navigationController?.navigationBar else { return }

        navbar.tintColor = .black
        navbar.titleTextAttributes = [.foregroundColor: UIColor.black]
        navbar.prefersLargeTitles = true

        // Set up the searchController parameters.
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
}

extension PokemonsViewController: PokemonsDisplayLogic {
    
    func displayFetchedPokemons(viewModel: Pokemons.FetchPokemons.ViewModel) {
        switch viewModel.result {
        case .success(let displayedPokemons):
            self.displayedPokemons = displayedPokemons
            self.didRefresh()

        case .failure(let error):
            print(":-( \(error)")
        }
    }
    
}

// MARK: - SearchBarDelegate

extension PokemonsViewController: SearchBarDelegate {
    
    // MARK: - UISearchViewController
    
    private func filterContentForSearchText(_ searchText: String) {
        // store latest search
        UserDefaults.standard.set(searchText, forKey: .searchText)
        // filter with a simple contains searched text
        resultPokemons = displayedPokemons
            .filter {
                searchText.isEmpty || $0.name.lowercased().contains(searchText.lowercased())
            }
            .sorted {
                $0.id < $1.id
            }
        
        collectionView.reloadData()
    }
    
    func updateSearchResults(for text: String) {
        filterContentForSearchText(text)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchController.showsCancelButton = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchController.showsCancelButton = !searchController.isSearchBarEmpty
    }
    
}

// MARK: - UICollectionViewDataSource

extension PokemonsViewController {
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return resultPokemons.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PokeCell.identifier, for: indexPath) as? PokeCell
        else { preconditionFailure("Failed to load collection view cell") }
        cell.pokemon = resultPokemons[indexPath.item]
        return cell
    }
    
}

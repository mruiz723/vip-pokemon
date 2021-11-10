//
//  PokemonsModels.swift
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

enum Pokemons {

    // MARK: Use cases
    
    enum FetchPokemons {
        struct Request { }

        struct Response {
            var result: Result<[Pokemon], NetworkingError>
        }

        struct ViewModel {
            struct DisplayedPokemon {
                let id: Int
                let name: String
                let image: String?
                let types: [String]?

                func formattedNumber() -> String {
                    String(format: "#%03d", arguments: [id])
                }

                func primaryType() -> String? {
                    guard let primary = types?.first else { return nil }
                    return primary.capitalized
                }

                func secondaryType() -> String? {
                    let index = 1
                    guard index < types?.count ?? 0 else { return nil }
                    return types?[index].capitalized
                }
            }

            var result: Result<[DisplayedPokemon], NetworkingError>
        }
    }
}
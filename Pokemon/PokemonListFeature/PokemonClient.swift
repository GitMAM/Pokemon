import ComposableArchitecture
import Foundation

// For simplicity I included all the networking code in the client but in a real app you will have a networking layer that should be passed or injected.

// MARK: - PokemonClient Dependency
/// A client for fetching Pokemon data from the network.
@DependencyClient
struct PokemonClient {
  /// Searches for Pokemon matching the query string.
  ///
  /// - Parameter query: The search query.
  /// - Returns: A `PokemonListResponse` containing the matching Pokemon.
  var search: @Sendable (_ query: String) async throws -> PokemonListResponse
  
  /// Fetches details for a specific Pokemon using a URL.
  ///
  /// - Parameter url: The URL for the Pokemon details.
  /// - Returns: A `PokemonDetailsResponse` containing the Pokemon details.
  var details: @Sendable (_ url: String) async throws -> Pokemon
  
  /// Fetches the initial list of Pokemon.
  ///
  /// - Returns: A `PokemonListResponse` containing the initial Pokemon list.
  var initialList: @Sendable () async throws -> PokemonListResponse
  
  /// Loads more Pokemon from a paginated list.
  ///
  /// - Parameter url: The URL for the next page of Pokemon.
  /// - Returns: A `PokemonListResponse` containing more Pokemon.
  var loadMore: @Sendable (_ url: String) async throws -> PokemonListResponse
}

extension DependencyValues {
  var pokemonClient: PokemonClient {
    get { self[PokemonClient.self] }
    set { self[PokemonClient.self] = newValue }
  }
}

extension PokemonClient: DependencyKey {
  /// The live implementation of `PokemonClient`.
  static let liveValue: PokemonClient = {
    // this could be injected e.g static func makeLive(networkService: NetworkService)
    let networkLayer = NetworkLayer()
    
    return PokemonClient(
      search: { query in
        // Implemented partial match search functionality for Pokémon names.
        // While the Pokémon API requires exact matches (e.g., "pikachu"),
        // this app allows users to search with partial inputs (e.g., "Pika").
        // This approach enhances user experience by accommodating typos and incomplete names,
        // making the app more intuitive and user-friendly.
        // It involves fetching a complete list of Pokémon names and performing client-side filtering,
        // which may not be the most efficient but significantly improves usability.
        // The caching will also work in our favour so we won't have to hit the API multiple times.
        let response: PokemonListResponse = try await networkLayer.fetchData(from: Constants.baseURL(limit: 2000))
        let filteredResults = response.results.filter { $0.name.contains(query.lowercased()) }
        return PokemonListResponse(count: filteredResults.count, next: response.next, previous: response.previous, results: filteredResults)
      },
      details: { url in
        guard let url = URL(string: url) else {
          throw PokemonClientError.invalidURL
        }
        return try await networkLayer.fetchData(from: url)
      },
      initialList: {
        return try await networkLayer.fetchData(from: Constants.baseURL())
      },
      loadMore: { url in
        guard let url = URL(string: url) else {
          throw PokemonClientError.invalidURL
        }
        return try await networkLayer.fetchData(from: url)
      }
    )
  }()
}

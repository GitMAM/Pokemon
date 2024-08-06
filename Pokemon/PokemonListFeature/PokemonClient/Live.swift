import Foundation
import ComposableArchitecture

// Live implementation of the UI
extension PokemonClient: DependencyKey {
  /// The live implementation of `PokemonClient`.
  static let liveValue: PokemonClient = {
    // this could be injected e.g static func makeLive(networkService: NetworkService)
    let networkLayer = NetworkLayer()
    
    return PokemonClient(
      search: { query in
        
        /*
         Implemented partial match search functionality for Pokémon names.
         While the Pokémon API requires exact matches (e.g., "pikachu"),
         this allows users to search with partial inputs (e.g., "Pika").
         This approach enhances user experience by accommodating typos and incomplete names,
         making the app more intuitive and user-friendly.
         implementation is fetching complete list of Pokémon names and performing client-side filtering,
         which may not be the most efficient but significantly improves usability.
         The caching will also work in our favour so we won't have to hit the API multiple times.
         
         Enables partial match searches (e.g., "chu" finds "Pikachu")
         Provides immediate response times for subsequent searches
         
         Trade-offs:
         - Initial load might be slower but subsequent searches are fast
         - Consumes more memory but offers more responsive user experience
         - May not include newly added Pokémon until cache is refreshed
         */
        
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

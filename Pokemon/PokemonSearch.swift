import ComposableArchitecture
import Foundation

@Reducer
struct PokemonSearch {
  @ObservableState
  struct State: Equatable {
    var results: [PokemonListResult] = []
    var resultDetailsRequestInFlight: PokemonListResult?
    var searchQuery = ""
    var pokemonDetails: PokemonDetails?
    var isLoading = false
    var nextPageURL: String?
    
    struct PokemonDetails: Equatable {
      var id: PokemonListResult.ID
      var weight: Int
      var height: Int
      var types: [String]
      var stats: [Stat]
      
      struct Stat: Equatable {
        var name: String
        var baseStat: Int
      }
    }
  }
  
  enum Action {
    case onAppear
    case initialListResponse(Result<PokemonListResponse, Error>)
    case detailsResponse(PokemonListResult.ID, Result<PokemonDetailsResponse, Error>)
    case searchQueryChanged(String)
    case searchQueryChangeDebounced
    case searchResponse(Result<PokemonListResponse, Error>)
    case searchResultTapped(PokemonListResult)
    case loadMoreIfNeeded
    case loadMoreResponse(Result<PokemonListResponse, Error>)
  }
  
  @Dependency(\.pokemonClient) var pokemonClient
  @Dependency(\.continuousClock) var clock
  private enum CancelID { case search, details, debounce }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.isLoading = true
        return .run { send in
          await send(.initialListResponse(Result { try await self.pokemonClient.initialList() }))
        }
        
      case let .initialListResponse(.success(response)):
        state.isLoading = false
        state.results = response.results
        return .none
        
      case .initialListResponse(.failure):
        state.isLoading = false
        // Handle error (e.g., show an alert)
        return .none
        
      case .detailsResponse(_, .failure):
        state.pokemonDetails = nil
        state.resultDetailsRequestInFlight = nil
        return .none
        
      case let .detailsResponse(id, .success(details)):
        state.pokemonDetails = State.PokemonDetails(
          id: id,
          weight: details.weight,
          height: details.height,
          types: details.types.map { $0.type.name },
          stats: details.stats.map { State.PokemonDetails.Stat(name: $0.stat.name, baseStat: $0.baseStat) }
        )
        state.resultDetailsRequestInFlight = nil
        return .none
        
      case let .searchQueryChanged(query):
        state.searchQuery = query
        
        guard !query.isEmpty else {
          return .send(.onAppear)
        }
        
        return .run { send in
          try await self.clock.sleep(for: .milliseconds(300))
          await send(.searchQueryChangeDebounced)
        }
        .cancellable(id: CancelID.debounce, cancelInFlight: true)
        
      case .searchQueryChangeDebounced:
        guard !state.searchQuery.isEmpty else {
          return .none
        }
        state.isLoading = true
        return .run { [query = state.searchQuery] send in
          await send(.searchResponse(Result { try await self.pokemonClient.search(query: query) }))
        }
        .cancellable(id: CancelID.search)
        
      case .searchResponse(.failure):
        state.results = []
        state.isLoading = false
        return .none
        
      case let .searchResponse(.success(response)):
        state.results = response.results
        state.isLoading = false
        return .none
        
      case let .searchResultTapped(pokemon):
        state.resultDetailsRequestInFlight = pokemon
        
        return .run { send in
          await send(
            .detailsResponse(
              pokemon.id,
              Result { try await self.pokemonClient.details(url: pokemon.url) }
            )
          )
        }
        .cancellable(id: CancelID.details, cancelInFlight: true)
        
      case .loadMoreIfNeeded:
        guard let nextPageURL = state.nextPageURL, !state.isLoading else { return .none }
        state.isLoading = true
        return .run { send in
          await send(.loadMoreResponse(Result { try await self.pokemonClient.loadMore(url: nextPageURL) }))
        }
        
      case let .loadMoreResponse(.success(response)):
        state.isLoading = false
        state.results.append(contentsOf: response.results)
        state.nextPageURL = response.next
        return .none
        
      case .loadMoreResponse(.failure):
        state.isLoading = false
        // Handle error
        return .none
      }
    }
  }
}

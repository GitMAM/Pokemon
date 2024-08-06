import ComposableArchitecture
import SwiftUI

@Reducer
struct PokemonSearch {
  @Reducer(state: .equatable)
  enum Destination {
    case details(PokemonDetails)
  }
  
  @ObservableState
  struct State: Equatable {
    @Presents var destination: Destination.State?
    var results: [PokemonListResult] = []
    var searchQuery = ""
    var isLoading = false
    var nextPageURL: String?
  }
  
  enum Action {
    case onAppear
    case initialListResponse(Result<PokemonListResponse, Error>)
    case searchQueryChanged(String)
    case searchQueryChangeDebounced
    case searchResponse(Result<PokemonListResponse, Error>)
    case pokemonTapped(PokemonListResult)
    case loadMoreIfNeeded
    case pokemonDetailsResponse(Result<PokemonDetailsResponse, Error>)
    case loadMoreResponse(Result<PokemonListResponse, Error>)
    case destination(PresentationAction<Destination.Action>)
  }
  
  @Dependency(\.pokemonClient) var pokemonClient
  @Dependency(\.continuousClock) var clock
  private enum CancelID { case search, debounce }
  
  var body: some ReducerOf<Self> {
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
        state.nextPageURL = response.next
        return .none
        
      case .initialListResponse(.failure):
        state.isLoading = false
        // Handle error (e.g., show an alert)
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
        
      case let .pokemonTapped(pokemon):
        return .run { send in
          await send(.pokemonDetailsResponse(Result {
            try await self.pokemonClient.details(url: pokemon.url)
          }))
        }
        
      case let .pokemonDetailsResponse(.success(details)):
        state.destination = .details(PokemonDetails.State(details: details))
        return .none
        
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
        
      case .destination:
        return .none
      case .pokemonDetailsResponse(.failure(_)):
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }
}

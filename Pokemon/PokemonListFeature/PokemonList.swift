import ComposableArchitecture
import SwiftUI

@Reducer
struct PokemonList {
  @Reducer(state: .equatable)
  enum Destination {
    case details(PokemonDetails)
  }
  
  @ObservableState
  struct State: Equatable {
    @Presents var destination: Destination.State?
    @Presents var alert: AlertState<Action.Alert>?
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
    case alert(PresentationAction<Alert>)
    
    enum Alert: Equatable {
      case error(String)
    }
  }
  
  enum Alert: Equatable {
    case error(String)
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
        state.results = []
        state.alert = .initialListFailed
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
          await send(.searchResponse(Result { try await self.pokemonClient.search(query)}))
        }
        .cancellable(id: CancelID.search)
        
      case let .searchResponse(.success(response)):
        state.results = response.results
        state.isLoading = false
        return .none
        
      case .searchResponse(.failure):
        state.results = []
        state.isLoading = false
        state.alert = .searchResponseFailed
        return .none
        
      case let .pokemonTapped(pokemon):
        return .run { send in
          await send(.pokemonDetailsResponse(Result {
            try await self.pokemonClient.details(pokemon.url)
          }))
        }
        
      case let .pokemonDetailsResponse(.success(details)):
        state.destination = .details(PokemonDetails.State(details: details))
        return .none
        
      case .pokemonDetailsResponse(.failure):
        state.alert = .pokemonDetailsFailed
        return .none
        
      case .loadMoreIfNeeded:
        guard let nextPageURL = state.nextPageURL, !state.isLoading else { return .none }
        state.isLoading = true
        return .run { send in
          await send(.loadMoreResponse(Result { try await self.pokemonClient.loadMore(nextPageURL)}))
        }
        
      case let .loadMoreResponse(.success(response)):
        state.isLoading = false
        state.results.append(contentsOf: response.results)
        state.nextPageURL = response.next
        return .none
        
      case .loadMoreResponse(.failure):
        state.isLoading = false
        state.alert = .loadMoreResultsFailed
        return .none
        
      case .destination:
        return .none
        
      case .alert:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
    .ifLet(\.$alert, action: \.alert)
  }
}


extension AlertState where Action == PokemonList.Action.Alert {
  static let searchResponseFailed = Self {
    TextState("Search Failed")
  } actions: {
    ButtonState(role: .cancel) {
      TextState("OK")
    }
  } message: {
    TextState("Search failed. Please try again later.")
  }
  
  static let pokemonDetailsFailed = Self {
    TextState("Load Failed")
  } actions: {
    ButtonState(role: .cancel) {
      TextState("OK")
    }
  } message: {
    TextState("Failed to load Pokémon details. Please try again later.")
  }
  
  static let loadMoreResultsFailed = Self {
    TextState("Load More Failed")
  } actions: {
    ButtonState(role: .cancel) {
      TextState("OK")
    }
  } message: {
    TextState("Failed to load more results. Please try again later.")
  }
  
  static let initialListFailed = Self {
    TextState("Initial Load Failed")
  } actions: {
    ButtonState(role: .cancel) {
      TextState("OK")
    }
  } message: {
    TextState("Failed to load initial list. Please try again later.")
  }
}

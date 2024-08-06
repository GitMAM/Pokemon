import ComposableArchitecture
import SwiftUI

// MARK: - PokemonList Reducer
/// The `PokemonList` reducer handles the state and actions related to the Pokemon list view.
@Reducer
struct PokemonList {
  /// Enum representing possible destinations in the application.
  /// This is a nested reducer for handling navigation to detailed views.
  @Reducer(state: .equatable)
  enum Destination {
    case details(PokemonDetails)
  }
  
  /// The state of the Pokemon list screen.
  @ObservableState
  struct State: Equatable {
    @Presents var destination: Destination.State?
    @Presents var alert: AlertState<Action.Alert>?
    var results: [PokemonListResult] = []
    var searchQuery = ""
    var isLoading = false
    var nextPageURL: String?
  }
  
  /// Enum representing possible actions for the Pokemon list.
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
  
  /// Dependency for accessing the PokemonClient.
  @Dependency(\.pokemonClient) var pokemonClient
  
  /// Dependency for accessing the continuous clock.
  @Dependency(\.continuousClock) var clock
  
  /// Enum representing cancellation identifiers for asynchronous operations.
  private enum CancelID { case search, debounce }
  
  /// The main body of the reducer, defining how actions change the state.
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


// MARK: - AlertState Extensions

/// Extensions for `AlertState` to define pre-configured alert states.
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

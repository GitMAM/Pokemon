import ComposableArchitecture
import XCTest
@testable import Pokemon

final class PokemonListTests: XCTestCase {
  @MainActor
  func testInitialLoad() async {
    let store = TestStore(initialState: PokemonList.State()) {
      PokemonList()
    } withDependencies: {
      $0.pokemonClient.initialList = { .mock }
    }
    
    await store.send(.onAppear) {
      $0.isLoading = true
    }
    await store.receive(\.initialListResponse.success) {
      $0.isLoading = false
      $0.results = PokemonListResponse.mock.results
      $0.nextPageURL = PokemonListResponse.mock.next
    }
  }
  
  @MainActor
  func testSearchQueryChanged() async {
    let store = TestStore(initialState: PokemonList.State()) {
      PokemonList()
    } withDependencies: {
      $0.pokemonClient.search = { @Sendable _ in .mock }
      $0.continuousClock = ImmediateClock()
    }
    
    await store.send(.searchQueryChanged("Pika")) {
      $0.searchQuery = "Pika"
    }
    await store.receive(\.searchQueryChangeDebounced) {
      $0.isLoading = true
    }
    await store.receive(\.searchResponse.success) {
      $0.results = PokemonListResponse.mock.results
      $0.isLoading = false
    }
  }
  
  
  @MainActor
  func testPokemonTapped() async {
    let pokemon = PokemonListResult(name: "Pikachu", url: "https://pokeapi.co/api/v2/pokemon/25/")
    let store = TestStore(initialState: PokemonList.State(results: [pokemon])) {
      PokemonList()
    } withDependencies: {
      $0.pokemonClient.details = { @Sendable _ in .mock }
    }
    
    await store.send(.pokemonTapped(pokemon))
    await store.receive(\.pokemonDetailsResponse.success) {
      $0.destination = .details(PokemonDetails.State(details: Pokemon.mock))
    }
  }
  
  
  @MainActor
  func testLoadMoreIfNeeded() async {
    let store = TestStore(initialState: PokemonList.State(results: [], nextPageURL: "https://pokeapi.co/api/v2/pokemon?offset=20&limit=20")) {
      PokemonList()
    } withDependencies: {
      $0.pokemonClient.loadMore = { @Sendable _ in .mock }
    }
    
    await store.send(.loadMoreIfNeeded) {
      $0.isLoading = true
    }
    await store.receive(\.loadMoreResponse.success) {
      $0.isLoading = false
      $0.results = PokemonListResponse.mock.results
      $0.nextPageURL = PokemonListResponse.mock.next
    }
  }
  
  @MainActor
  func testSearchFailure() async {
    let store = TestStore(initialState: PokemonList.State()) {
      PokemonList()
    } withDependencies: {
      $0.pokemonClient.search = { @Sendable _ in
        struct SomethingWentWrong: Error {}
        throw SomethingWentWrong()
      }
      $0.continuousClock = ImmediateClock()
    }
    
    await store.send(.searchQueryChanged("Pika")) {
      $0.searchQuery = "Pika"
    }
    await store.receive(\.searchQueryChangeDebounced) {
      $0.isLoading = true
    }
    await store.receive(\.searchResponse.failure) {
      $0.isLoading = false
      $0.results = []
      $0.alert = .searchResponseFailed
    }
  }
  
  
  @MainActor
  func testInitialLoadFailure() async {
    let store = TestStore(initialState: PokemonList.State()) {
      PokemonList()
    } withDependencies: {
      $0.pokemonClient.initialList = {
        struct InitialLoadError: Error {}
        throw InitialLoadError()
      }
    }
    
    await store.send(.onAppear) {
      $0.isLoading = true
    }
    await store.receive(\.initialListResponse.failure) {
      $0.isLoading = false
      $0.alert = .initialListFailed
    }
  }
  
  @MainActor
  func testLoadMoreFailure() async {
    let store = TestStore(initialState: PokemonList.State(nextPageURL: "https://example.com/next")) {
      PokemonList()
    } withDependencies: {
      $0.pokemonClient.loadMore = { @Sendable _ in
        struct LoadMoreError: Error {}
        throw LoadMoreError()
      }
    }
    
    await store.send(.loadMoreIfNeeded) {
      $0.isLoading = true
    }
    await store.receive(\.loadMoreResponse.failure) {
      $0.isLoading = false
      $0.alert = .loadMoreResultsFailed
    }
  }
  
  @MainActor
  func testPokemonDetailsFailure() async {
    let pokemon = PokemonListResult(name: "Pikachu", url: "https://pokeapi.co/api/v2/pokemon/25/")
    let store = TestStore(initialState: PokemonList.State(results: [pokemon])) {
      PokemonList()
    } withDependencies: {
      $0.pokemonClient.details = { @Sendable _ in
        struct DetailsError: Error {}
        throw DetailsError()
      }
    }
    
    await store.send(.pokemonTapped(pokemon))
    await store.receive(\.pokemonDetailsResponse.failure) {
      $0.alert = .pokemonDetailsFailed
    }
  }
  
  @MainActor
  func testEmptySearchQuery() async {
    let store = TestStore(initialState: PokemonList.State(searchQuery: "Pika")) {
      PokemonList()
    } withDependencies: {
      $0.pokemonClient.initialList = { .mock }
      $0.continuousClock = ImmediateClock()
    }
    
    await store.send(.searchQueryChanged("")) {
      $0.searchQuery = ""
    }
    
    await store.receive(\.onAppear) {
      $0.isLoading = true
    }
    
    await store.receive(\.initialListResponse.success) {
      $0.isLoading = false
      $0.results = PokemonListResponse.mock.results
      $0.nextPageURL = PokemonListResponse.mock.next
    }
  }
}

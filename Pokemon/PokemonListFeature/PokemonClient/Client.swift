import Foundation
import ComposableArchitecture

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


// TestDependency implementation for the swiftUI previews and tests
extension PokemonClient: TestDependencyKey {
  static let previewValue = Self(
    search: { _ in .mock},
    details: {_ in .mock},
    initialList: { return .mock },
    loadMore: {_ in .mock }
  )
  static let testValue = Self(
    search: { _ in .mock},
    details: {_ in .mock},
    initialList: { return .mock },
    loadMore: {_ in .mock }
  )
}

extension DependencyValues {
  var pokemonClient: PokemonClient {
    get { self[PokemonClient.self] }
    set { self[PokemonClient.self] = newValue }
  }
}

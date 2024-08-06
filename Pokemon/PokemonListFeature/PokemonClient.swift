import ComposableArchitecture
import Foundation

struct PokemonListResult: Decodable, Equatable, Identifiable, Sendable {
  let name: String
  let url: String
  
  var id: Int {
    Int(url.split(separator: "/").last ?? "0") ?? 0
  }
}

struct PokemonListResponse: Decodable, Equatable, Sendable {
  let count: Int
  let next: String?
  let previous: String?
  let results: [PokemonListResult]
}

struct PokemonDetailsResponse: Decodable, Equatable, Sendable {
  let id: Int
  let name: String
  let height: Int
  let weight: Int
  let types: [TypeElement]
  let stats: [Stat]
  
  struct TypeElement: Decodable, Equatable, Sendable {
    let type: Type
  }
  
  struct `Type`: Decodable, Equatable, Sendable {
    let name: String
  }
  
  struct Stat: Decodable, Equatable, Sendable {
    let baseStat: Int
    let stat: StatInfo
    
    enum CodingKeys: String, CodingKey {
      case baseStat = "base_stat"
      case stat
    }
  }
  
  struct StatInfo: Decodable, Equatable, Sendable {
    let name: String
  }
}

@DependencyClient
struct PokemonClient {
  let search: @Sendable (_ query: String) async throws -> PokemonListResponse
  let details: @Sendable (_ url: String) async throws -> PokemonDetailsResponse
  let initialList: @Sendable () async throws -> PokemonListResponse
  let loadMore: @Sendable (_ url: String) async throws -> PokemonListResponse
}

extension DependencyValues {
  var pokemonClient: PokemonClient {
    get { self[PokemonClient.self] }
    set { self[PokemonClient.self] = newValue }
  }
}

extension PokemonClient: DependencyKey {
  static let liveValue = PokemonClient(
    search: { query in
      let url = URL(string: "https://pokeapi.co/api/v2/pokemon?limit=20&offset=0")!
      let (data, _) = try await URLSession.shared.data(from: url)
      let response = try JSONDecoder().decode(PokemonListResponse.self, from: data)
      let filteredResults = response.results.filter { $0.name.contains(query.lowercased()) }
      return PokemonListResponse(count: filteredResults.count, next: response.next, previous: response.previous, results: filteredResults)
    },
    details: { url in
      let (data, _) = try await URLSession.shared.data(from: URL(string: url)!)
      return try JSONDecoder().decode(PokemonDetailsResponse.self, from: data)
    },
    initialList: {
      let url = URL(string: "https://pokeapi.co/api/v2/pokemon?limit=20&offset=0")!
      let (data, _) = try await URLSession.shared.data(from: url)
      return try JSONDecoder().decode(PokemonListResponse.self, from: data)
    },
    loadMore: { url in
      let (data, _) = try await URLSession.shared.data(from: URL(string: url)!)
      return try JSONDecoder().decode(PokemonListResponse.self, from: data)
    }
  )
}

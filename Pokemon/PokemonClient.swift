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
  var results: [PokemonListResult]
  var next: String?
}

struct PokemonDetailsResponse: Decodable, Equatable, Sendable {
  var id: Int
  var name: String
  var height: Int
  var weight: Int
  var types: [TypeElement]
  var stats: [Stat]
  
  struct TypeElement: Decodable, Equatable, Sendable {
    var type: Type
  }
  
  struct `Type`: Decodable, Equatable, Sendable {
    var name: String
  }
  
  struct Stat: Decodable, Equatable, Sendable {
    var baseStat: Int
    var stat: StatInfo
    
    enum CodingKeys: String, CodingKey {
      case baseStat = "base_stat"
      case stat
    }
  }
  
  struct StatInfo: Decodable, Equatable, Sendable {
    var name: String
  }
}

@DependencyClient
struct PokemonClient {
  var search: @Sendable (_ query: String) async throws -> PokemonListResponse
  var details: @Sendable (_ url: String) async throws -> PokemonDetailsResponse
  var initialList: @Sendable () async throws -> PokemonListResponse
  var loadMore: @Sendable (_ url: String) async throws -> PokemonListResponse
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
      return PokemonListResponse(
        results: response.results.filter { $0.name.contains(query.lowercased()) },
        next: response.next
      )
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

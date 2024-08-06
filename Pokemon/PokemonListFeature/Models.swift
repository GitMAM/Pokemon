import Foundation

// MARK: - Data Models
/// Represents a single Pokemon result from the list response.
struct PokemonListResult: Decodable, Equatable, Identifiable, Sendable {
  let name: String
  let url: String
  
  var id: Int {
    // Extract ID from URL
    Int(url.split(separator: "/").last ?? "0") ?? 0
  }
}

/// Represents the response from the Pokemon list API.
struct PokemonListResponse: Decodable, Equatable, Sendable {
  let count: Int
  let next: String?
  let previous: String?
  let results: [PokemonListResult]
}

/// Represents the detailed response for a specific Pokemon.
struct Pokemon: Decodable, Equatable, Sendable {
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

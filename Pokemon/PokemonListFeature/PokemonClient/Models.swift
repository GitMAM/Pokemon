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

// MARK: - Mocks for testing and previews
extension PokemonListResponse {
  static let mock = Self(
    count: 10,
    next: "https://pokeapi.co/api/v2/pokemon?offset=20&limit=20",
    previous: "https://pokeapi.co/api/v2/pokemon?offset=0&limit=20",
    results: [
      PokemonListResult(name: "Bulbasaur", url: "https://pokeapi.co/api/v2/pokemon/1/"),
      PokemonListResult(name: "Charmander", url: "https://pokeapi.co/api/v2/pokemon/4/"),
      PokemonListResult(name: "Squirtle", url: "https://pokeapi.co/api/v2/pokemon/7/"),
      PokemonListResult(name: "Pikachu", url: "https://pokeapi.co/api/v2/pokemon/25/"),
      PokemonListResult(name: "Jigglypuff", url: "https://pokeapi.co/api/v2/pokemon/39/"),
      PokemonListResult(name: "Meowth", url: "https://pokeapi.co/api/v2/pokemon/52/"),
      PokemonListResult(name: "Psyduck", url: "https://pokeapi.co/api/v2/pokemon/54/"),
      PokemonListResult(name: "Machop", url: "https://pokeapi.co/api/v2/pokemon/66/"),
      PokemonListResult(name: "Gengar", url: "https://pokeapi.co/api/v2/pokemon/94/"),
      PokemonListResult(name: "Eevee", url: "https://pokeapi.co/api/v2/pokemon/133/")
    ]
  )
}

extension Pokemon {
  static let mock = Self(
    id: 25,
    name: "Pikachu",
    height: 10,
    weight: 20,
    types: [
      TypeElement(type: Type(name: "Electric"))
    ],
    stats: [
      Stat(baseStat: 55, stat: StatInfo(name: "hp")),
      Stat(baseStat: 40, stat: StatInfo(name: "attack")),
      Stat(baseStat: 50, stat: StatInfo(name: "defense")),
      Stat(baseStat: 90, stat: StatInfo(name: "speed"))
    ]
  )
}


import ComposableArchitecture
import Foundation

// MARK: - Data Models
struct PokemonListResult: Decodable, Equatable, Identifiable, Sendable {
  let name: String
  let url: String
  
  var id: Int {
    // Extract ID from URL
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

// MARK: - PokemonClient Error Handling

enum PokemonClientError: Error, LocalizedError, Equatable {
  case invalidURL
  case networkError(Error)
  case decodingError(Error)
  
  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "The URL is invalid."
    case .networkError(let error):
      return "Network error occurred: \(error.localizedDescription)"
    case .decodingError(let error):
      return "Failed to decode response: \(error.localizedDescription)"
    }
  }
  
  static func == (lhs: PokemonClientError, rhs: PokemonClientError) -> Bool {
    lhs.errorDescription == rhs.errorDescription
  }
}

// MARK: - PokemonClient Dependency
@DependencyClient
struct PokemonClient {
  var search: @Sendable (_ query: String) async throws -> PokemonListResponse
  var details: @Sendable (_ url: String) async throws -> PokemonDetailsResponse
  var initialList: @Sendable () async throws -> PokemonListResponse
  var loadMore: @Sendable (_ url: String) async throws -> PokemonListResponse
  
  // Generic network call function
  static private func fetchData<T: Decodable>(from url: URL) async throws -> T {
    do {
      let (data, _) = try await urlSession.data(from: url)
      return try decodeJSON(data)
    } catch let error as DecodingError {
      throw PokemonClientError.decodingError(error)
    } catch {
      throw PokemonClientError.networkError(error)
    }
  }
  
  // JSON decoding function
  static private func decodeJSON<T: Decodable>(_ data: Data) throws -> T {
    let decoder = JSONDecoder()
    return try decoder.decode(T.self, from: data)
  }
  
  // URLSession configuration for caching
  static private let urlSession: URLSession = {
    let configuration = URLSessionConfiguration.default
    configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
    configuration.urlCache = URLCache(memoryCapacity: 512_000, diskCapacity: 10_000_000, diskPath: nil)
    return URLSession(configuration: configuration)
  }()
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
      guard let url = URL(string: "https://pokeapi.co/api/v2/pokemon?limit=20&offset=0") else {
        throw PokemonClientError.invalidURL
      }
      let response: PokemonListResponse = try await fetchData(from: url)
      let filteredResults = response.results.filter { $0.name.contains(query.lowercased()) }
      return PokemonListResponse(count: filteredResults.count, next: response.next, previous: response.previous, results: filteredResults)
    },
    details: { url in
      guard let url = URL(string: url) else {
        throw PokemonClientError.invalidURL
      }
      return try await fetchData(from: url)
    },
    initialList: {
      guard let url = URL(string: "https://pokeapi.co/api/v2/pokemon?limit=20&offset=0") else {
        throw PokemonClientError.invalidURL
      }
      return try await fetchData(from: url)
    },
    loadMore: { url in
      guard let url = URL(string: url) else {
        throw PokemonClientError.invalidURL
      }
      return try await fetchData(from: url)
    }
  )
}

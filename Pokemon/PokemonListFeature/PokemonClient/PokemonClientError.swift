import Foundation

// MARK: - PokemonClient Error Handling
/// Enum representing errors that can occur in the PokemonClient.
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

import Foundation

enum Constants {
  static let navigationTitle = "Pokémon Search"
  static let searchIconName = "magnifyingglass"
  static let searchPlaceholder = "Pikachu, Charizard, ..."
  static let horizontalPadding: CGFloat = 16
  static let dividerOpacity: Double = 0.3
  static let dividerHeight: CGFloat = 1
  static let rowVerticalPadding: CGFloat = 8
  static let rowHorizontalPadding: CGFloat = 16
  
  // details view
  static let imageSize: CGFloat = 200
  static let verticalSpacing: CGFloat = 20
  static let infoSpacing: CGFloat = 8
  
  // urls
  static func baseURL(limit: Int = 20) throws -> URL {
    guard let url = URL(string: "https://pokeapi.co/api/v2/pokemon?limit=\(limit)&offset=0") else {
      throw PokemonClientError.invalidURL
    }
    return url
  }
}

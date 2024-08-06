import Foundation
// this is very simplified implementation of a networking layer to handle the fetching of data from the api, in a real app this would be more complex maybe use a protocol etc ..

// MARK: - NetworkLayer
struct NetworkLayer {
  // URLSession configuration for caching
  private let urlSession: URLSession
  
  init() {
    let configuration = URLSessionConfiguration.default
    configuration.requestCachePolicy = .returnCacheDataElseLoad
    configuration.urlCache = URLCache(memoryCapacity: 512_000, diskCapacity: 10_000_000, diskPath: nil)
    self.urlSession = URLSession(configuration: configuration)
  }
  
  /// Generic network call function to fetch data and decode it.
  ///
  /// - Parameter url: The URL to fetch data from.
  /// - Returns: A decoded object of type `T`.
  func fetchData<T: Decodable>(from url: URL) async throws -> T {
    do {
      let (data, _) = try await urlSession.data(from: url)
      return try decodeJSON(data)
    } catch let error as DecodingError {
      throw PokemonClientError.decodingError(error)
    } catch {
      throw PokemonClientError.networkError(error)
    }
  }
  
  /// Decodes JSON data into a specified type.
  ///
  /// - Parameter data: The JSON data to decode.
  /// - Returns: A decoded object of type `T`.
  private func decodeJSON<T: Decodable>(_ data: Data) throws -> T {
    let decoder = JSONDecoder()
    return try decoder.decode(T.self, from: data)
  }
}

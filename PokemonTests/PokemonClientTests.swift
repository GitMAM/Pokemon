import ComposableArchitecture
import XCTest
@testable import Pokemon

final class PokemonClientTests: XCTestCase {
  func testSearchSuccessWithMockData() async throws {
    let client = PokemonClient(
      search: { _ in PokemonListResponse.mock },
      details: { _ in Pokemon.mock },
      initialList: { PokemonListResponse.mock },
      loadMore: { _ in PokemonListResponse.mock }
    )
    
    do {
      let response = try await client.search("Pikachu")
      XCTAssertEqual(response.count, 10)
      XCTAssertEqual(response.results.first?.name, "Bulbasaur")
    } catch {
      XCTFail("Expected successful response, but got error: \(error)")
    }
  }
  
  func testDetailsSuccessWithMockData() async throws {
    let client = PokemonClient(
      search: { _ in PokemonListResponse.mock },
      details: { _ in Pokemon.mock },
      initialList: { PokemonListResponse.mock },
      loadMore: { _ in PokemonListResponse.mock }
    )
    
    do {
      let response = try await client.details("https://pokeapi.co/api/v2/pokemon/25/")
      XCTAssertEqual(response.id, 25)
      XCTAssertEqual(response.name, "Pikachu")
      XCTAssertEqual(response.types.first?.type.name, "Electric")
    } catch {
      XCTFail("Expected successful response, but got error: \(error)")
    }
  }
  
  func testSearchFailure() async {
    let client = PokemonClient(
      search: { _ in throw PokemonClientError.networkError(NSError(domain: "", code: -1, userInfo: nil)) },
      details: { _ in Pokemon.mock },
      initialList: { PokemonListResponse.mock },
      loadMore: { _ in PokemonListResponse.mock }
    )
    
    do {
      _ = try await client.search("Pikachu")
      XCTFail("Expected failure, but got successful response")
    } catch let error as PokemonClientError {
      XCTAssertEqual(error, PokemonClientError.networkError(NSError(domain: "", code: -1, userInfo: nil)))
    } catch {
      XCTFail("Unexpected error type: \(error)")
    }
  }
  
  func testInitialListSuccessWithMockData() async throws {
    let client = PokemonClient(
      search: { _ in PokemonListResponse.mock },
      details: { _ in Pokemon.mock },
      initialList: { PokemonListResponse.mock },
      loadMore: { _ in PokemonListResponse.mock }
    )
    
    do {
      let response = try await client.initialList()
      XCTAssertEqual(response.count, 10)
      XCTAssertEqual(response.results.first?.name, "Bulbasaur")
    } catch {
      XCTFail("Expected successful response, but got error: \(error)")
    }
  }
  
  func testInitialListFailure() async {
    let client = PokemonClient(
      search: { _ in PokemonListResponse.mock },
      details: { _ in Pokemon.mock },
      initialList: { throw PokemonClientError.invalidURL },
      loadMore: { _ in PokemonListResponse.mock }
    )
    
    do {
      _ = try await client.initialList()
      XCTFail("Expected failure, but got successful response")
    } catch let error as PokemonClientError {
      XCTAssertEqual(error, PokemonClientError.invalidURL)
    } catch {
      XCTFail("Unexpected error type: \(error)")
    }
  }
  
  func testDetailsFailure() async {
    let client = PokemonClient(
      search: { _ in PokemonListResponse.mock },
      details: { _ in throw PokemonClientError.decodingError(NSError(domain: "", code: -1, userInfo: nil)) },
      initialList: { PokemonListResponse.mock },
      loadMore: { _ in PokemonListResponse.mock }
    )
    
    do {
      _ = try await client.details("https://pokeapi.co/api/v2/pokemon/25/")
      XCTFail("Expected failure, but got successful response")
    } catch let error as PokemonClientError {
      XCTAssertEqual(error, PokemonClientError.decodingError(NSError(domain: "", code: -1, userInfo: nil)))
    } catch {
      XCTFail("Unexpected error type: \(error)")
    }
  }
  
  func testLoadMoreSuccessWithMockData() async throws {
    let client = PokemonClient(
      search: { _ in PokemonListResponse.mock },
      details: { _ in Pokemon.mock },
      initialList: { PokemonListResponse.mock },
      loadMore: { _ in PokemonListResponse.mock }
    )
    
    do {
      let response = try await client.loadMore("https://pokeapi.co/api/v2/pokemon?offset=20&limit=20")
      XCTAssertEqual(response.count, 10)
      XCTAssertEqual(response.results.first?.name, "Bulbasaur")
    } catch {
      XCTFail("Expected successful response, but got error: \(error)")
    }
  }
  
  func testLoadMoreFailure() async {
    let client = PokemonClient(
      search: { _ in PokemonListResponse.mock },
      details: { _ in Pokemon.mock },
      initialList: { PokemonListResponse.mock },
      loadMore: { _ in throw PokemonClientError.networkError(NSError(domain: "", code: -1, userInfo: nil)) }
    )
    
    do {
      _ = try await client.loadMore("https://pokeapi.co/api/v2/pokemon?offset=20&limit=20")
      XCTFail("Expected failure, but got successful response")
    } catch let error as PokemonClientError {
      XCTAssertEqual(error, PokemonClientError.networkError(NSError(domain: "", code: -1, userInfo: nil)))
    } catch {
      XCTFail("Unexpected error type: \(error)")
    }
  }
  
  func testEmptySearchResult() async throws {
    let client = PokemonClient(
      search: { _ in
        PokemonListResponse(count: 0, next: nil, previous: nil, results: [])
      },
      details: { _ in Pokemon.mock },
      initialList: { PokemonListResponse.mock },
      loadMore: { _ in PokemonListResponse.mock }
    )
    
    do {
      let response = try await client.search("UnknownPokemon")
      XCTAssertEqual(response.count, 0)
      XCTAssertTrue(response.results.isEmpty, "Expected no results for unknown search")
    } catch {
      XCTFail("Expected successful response, but got error: \(error)")
    }
  }
  
  func testInvalidURLHandling() async {
    let client = PokemonClient(
      search: { _ in PokemonListResponse.mock },
      details: { _ in throw PokemonClientError.invalidURL },
      initialList: { PokemonListResponse.mock },
      loadMore: { _ in PokemonListResponse.mock }
    )
    
    do {
      _ = try await client.details("invalid-url")
      XCTFail("Expected failure due to invalid URL, but got successful response")
    } catch let error as PokemonClientError {
      XCTAssertEqual(error, PokemonClientError.invalidURL)
    } catch {
      XCTFail("Unexpected error type: \(error)")
    }
  }
}

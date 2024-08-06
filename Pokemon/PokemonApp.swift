import SwiftUI
import ComposableArchitecture

@main
struct PokemonApp: App {
  var body: some Scene {
    WindowGroup {
      PokemonSearchView(
        store: Store(initialState: PokemonSearch.State()) {
          PokemonSearch()
            ._printChanges()
        }
      )
    }
  }
}

import SwiftUI
import ComposableArchitecture

@main
struct PokemonApp: App {
  var body: some Scene {
    WindowGroup {
      PokemonListView(
        store: Store(initialState: PokemonList.State()) {
          PokemonList()
          // for debug uncomment this line.
//            ._printChanges()
        }
      )
    }
  }
}

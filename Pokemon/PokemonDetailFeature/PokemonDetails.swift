import Foundation
import ComposableArchitecture

@Reducer
struct PokemonDetails {
  @ObservableState
  struct State: Equatable {
    let details: Pokemon
  }

  enum Action {}

  var body: some ReducerOf<Self> {
    EmptyReducer()
  }
}

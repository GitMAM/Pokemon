import Foundation
import ComposableArchitecture

@Reducer
struct PokemonDetails {
  @ObservableState
  struct State: Equatable {
    let details: PokemonDetailsResponse
  }

  enum Action {}

  var body: some ReducerOf<Self> {
    EmptyReducer()
  }
}

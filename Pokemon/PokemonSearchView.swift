import ComposableArchitecture
import SwiftUI

struct PokemonSearchView: View {
  @Bindable var store: StoreOf<PokemonSearch>

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading) {
        HStack {
          Image(systemName: "magnifyingglass")
          TextField(
            "Pikachu, Charizard, ...", text: $store.searchQuery.sending(\.searchQueryChanged)
          )
          .textFieldStyle(.roundedBorder)
          .autocapitalization(.none)
          .disableAutocorrection(true)
        }
        .padding(.horizontal, 16)

        ScrollView {
          LazyVStack {
            ForEach(store.results) { pokemon in
              PokemonRow(store: store, pokemon: pokemon)
                .onAppear {
                  if pokemon.id == store.results.last?.id {
                    store.send(.loadMoreIfNeeded)
                  }
                }
            }

            if store.isLoading {
              ProgressView()
                .frame(maxWidth: .infinity)
                .padding()
            }
          }
        }

        Button("Pokémon data provided by PokeAPI") {
          UIApplication.shared.open(URL(string: "https://pokeapi.co")!)
        }
        .foregroundColor(.gray)
        .padding(.all, 16)
      }
      .navigationTitle("Pokémon Search")
    }
    .onAppear { store.send(.onAppear) }
  }
}

struct PokemonRow: View {
  let store: StoreOf<PokemonSearch>
  let pokemon: PokemonListResult

  var body: some View {
    VStack(alignment: .leading) {
      Button {
        store.send(.searchResultTapped(pokemon))
      } label: {
        HStack {
          Text(pokemon.name.capitalized)

          if store.resultDetailsRequestInFlight?.id == pokemon.id {
            ProgressView()
          }
        }
      }

      if pokemon.id == store.pokemonDetails?.id {
        pokemonDetailsView(details: store.pokemonDetails)
      }
    }
    .padding(.vertical, 8)
  }

  @ViewBuilder
  func pokemonDetailsView(details: PokemonSearch.State.PokemonDetails?) -> some View {
    if let details {
      VStack(alignment: .leading) {
        Text("Height: \(details.height)")
        Text("Weight: \(details.weight)")
        Text("Types: \(details.types.joined(separator: ", "))")
        ForEach(details.stats, id: \.name) { stat in
          Text("\(stat.name.capitalized): \(stat.baseStat)")
        }
      }
      .padding(.leading, 16)
    }
  }
}

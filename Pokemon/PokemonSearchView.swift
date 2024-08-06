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
              PokemonRow(pokemon: pokemon)
                .onTapGesture {
                  store.send(.pokemonTapped(pokemon))
                }
                .onAppear {
                  if pokemon.id == store.results.last?.id {
                    store.send(.loadMoreIfNeeded)
                  }
                }
              
              Divider()
                .background(Color.gray.opacity(0.3))
                .frame(height: 1)
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
    .sheet(
      item: $store.scope(state: \.destination?.details, action: \.destination.details)
    ) { detailsStore in
      NavigationStack {
        PokemonDetailsView(store: detailsStore)
      }
    }
  }
}

struct PokemonRow: View {
  let pokemon: PokemonListResult
  
  var body: some View {
    HStack {
      Text(pokemon.name.capitalized)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 16)
  }
}

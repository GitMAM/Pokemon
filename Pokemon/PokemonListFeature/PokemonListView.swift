import SwiftUI
import ComposableArchitecture

struct PokemonListView: View {
  @Bindable private var store: StoreOf<PokemonList>
  
  init(store: StoreOf<PokemonList>) {
    self.store = store
  }
  
  var body: some View {
    NavigationStack {
      VStack(alignment: .leading) {
        searchField
        resultsList
      }
      .navigationTitle(Constants.navigationTitle)
      .alert($store.scope(state: \.alert, action: \.alert))
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
  
  private var searchField: some View {
    HStack {
      Image(systemName: Constants.searchIconName)
      TextField(Constants.searchPlaceholder, text: $store.searchQuery.sending(\.searchQueryChanged))
        .textFieldStyle(.roundedBorder)
        .autocapitalization(.none)
        .disableAutocorrection(true)
    }
    .padding(.horizontal, Constants.horizontalPadding)
  }
  
  private var resultsList: some View {
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
            .background(Color.gray.opacity(Constants.dividerOpacity))
            .frame(height: Constants.dividerHeight)
        }
        
        if store.isLoading {
          ProgressView()
            .frame(maxWidth: .infinity)
            .padding()
        }
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
    .padding(.vertical, Constants.rowVerticalPadding)
    .padding(.horizontal, Constants.rowHorizontalPadding)
  }
}

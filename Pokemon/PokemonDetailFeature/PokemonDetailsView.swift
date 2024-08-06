import SwiftUI
import ComposableArchitecture

struct PokemonDetailsView: View {
  private let store: StoreOf<PokemonDetails>
  
  init(store: StoreOf<PokemonDetails>) {
    self.store = store
  }
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
        pokemonImage
        pokemonName
        basicInfo
        statsInfo
      }
      .padding()
    }
    .navigationTitle(store.details.name.capitalized)
  }
  
  private var pokemonImage: some View {
    AsyncImage(url: imageURL) { image in
      image.resizable()
    } placeholder: {
      ProgressView()
    }
    .frame(width: Constants.imageSize, height: Constants.imageSize)
    .padding()
  }
  
  private var pokemonName: some View {
    Text(store.details.name.capitalized)
      .font(.title)
      .fontWeight(.bold)
  }
  
  private var basicInfo: some View {
    VStack(alignment: .leading, spacing: Constants.infoSpacing) {
      InfoRow(label: "Height", value: "\(store.details.height)")
      InfoRow(label: "Weight", value: "\(store.details.weight)")
      InfoRow(label: "Types", value: types)
    }
  }
  
  private var statsInfo: some View {
    VStack(alignment: .leading, spacing: Constants.infoSpacing) {
      Text("Stats")
        .font(.headline)
      ForEach(store.details.stats, id: \.stat.name) { stat in
        InfoRow(label: stat.stat.name.capitalized, value: "\(stat.baseStat)")
      }
    }
  }
  
  private var imageURL: URL? {
    URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(store.details.id).png")
  }
  
  private var types: String {
    store.details.types.map { $0.type.name }.joined(separator: ", ")
  }
}

struct InfoRow: View {
  let label: String
  let value: String
  
  var body: some View {
    HStack {
      Text(label)
        .fontWeight(.medium)
      Spacer()
      Text(value)
    }
  }
}

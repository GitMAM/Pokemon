import SwiftUI
import ComposableArchitecture

struct PokemonDetailsView: View {
  let store: StoreOf<PokemonDetails>
  
  var body: some View {
    VStack(alignment: .leading) {
      AsyncImage(url: URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(store.details.id).png")) { image in
        image.resizable()
      } placeholder: {
        ProgressView()
      }
      .frame(width: 200, height: 200)
      .padding()
      
      Text(store.details.name.capitalized)
        .font(.title)
      
      Text("Height: \(store.details.height)")
      Text("Weight: \(store.details.weight)")
      Text("Types: \(store.details.types.map { $0.type.name }.joined(separator: ", "))")
      
      ForEach(store.details.stats, id: \.stat.name) { stat in
        Text("\(stat.stat.name.capitalized): \(stat.baseStat)")
      }
    }
    .padding()
    .navigationTitle(store.details.name.capitalized)
  }
}

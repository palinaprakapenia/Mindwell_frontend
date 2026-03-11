import SwiftUI

struct FavouritesView: View {
    @EnvironmentObject private var meditationVM: MeditationLibraryViewModel
    @Namespace private var animation
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Ulubione")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Spacer()
            }
            .padding(.top, 20)
            .padding(.horizontal)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    if meditationVM.favouriteMeditations.isEmpty {
                        Text("Brak ulubionych medytacji")
                            .foregroundColor(.gray)
                            .padding(.top, 50)
                    } else {
                        ForEach(meditationVM.favouriteMeditations) { item in
                            Button {
                                meditationVM.goToDetail(id: item.id, fromFavourites: true, fromHistory: false)
                            } label: {
                                MeditationCard(
                                    meditationId: item.id,
                                    animation: animation,
                                    isFavouriteView: true
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color(hex: "#F8F3ED").ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    meditationVM.goToRoot()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Główna")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(Color(hex: "#6BA59B"))
                }
            }
        }
        .onAppear {
            Task { await meditationVM.fetchMeditations() }
        }
    }
}

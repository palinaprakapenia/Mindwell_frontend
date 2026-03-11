import SwiftUI

public struct LibraryView: View {
    @EnvironmentObject var viewModel: MeditationLibraryViewModel
    @Namespace private var animation
    
    let categories = ["Sen", "Ćwiczenia oddechowe", "Medytacje"]
    let durations = ["5 min", "10 min", "15 min", "20+ min"]
    let difficulties = ["Łatwy", "Średni", "Trudny"]
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Biblioteka Medytacji")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Spacer()
            }
            .padding(.top, 20)
            .padding(.horizontal)
            
            VStack(spacing: 15) {
                TextField("Szukaj...", text: $viewModel.searchText)
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .onChange(of: viewModel.searchText) { _ in viewModel.applyFilters() }
                
                HStack(spacing: 10) {
                    Picker("Kategoria", selection: $viewModel.selectedCategory) {
                        Text("Wszystko").tag(String?.none)
                        ForEach(categories, id: \.self) { Text($0).tag(String?.some($0)) }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 120)
                    .onChange(of: viewModel.selectedCategory) { _ in viewModel.applyFilters() }
                    
                    Picker("Czas", selection: $viewModel.selectedDuration) {
                        Text("Wszystko").tag(String?.none)
                        ForEach(durations, id: \.self) { Text($0).tag(String?.some($0)) }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 120)
                    .onChange(of: viewModel.selectedDuration) { _ in viewModel.applyFilters() }
                    
                    Picker("Poziom", selection: $viewModel.selectedDifficulty) {
                        Text("Wszystko").tag(String?.none)
                        ForEach(difficulties, id: \.self) { Text($0).tag(String?.some($0)) }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 120)
                    .onChange(of: viewModel.selectedDifficulty) { _ in viewModel.applyFilters() }
                }
                .padding(.horizontal)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.meditations) { item in
                            Button {
                                viewModel.goToDetail(id: item.id)
                            } label: {
                                MeditationCard(
                                    meditationId: item.id,
                                    animation: animation
                                )
                                .matchedGeometryEffect(id: item.id, in: animation)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, 10)
        }
        .background(Color(hex: "#F8F3ED").ignoresSafeArea())
        .navigationBarHidden(true)
        .navigationDestination(for: MeditationLibraryViewModel.NavigationDestination.self) { destination in
            switch destination {
            case .detail(let id, let backTitle):
                MeditationDetailView(meditationId: id, backTitle: backTitle)
            case .favourites:
                FavouritesView()
            case .history:
                HistoryView()
            }
        }
        .onAppear {
            Task { await viewModel.fetchMeditations() }
        }
    }
}

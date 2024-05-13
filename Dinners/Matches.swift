//
//  RecipesList.swift
//  FryDay
//
//  Created by Theo Goodman on 1/18/23.
//

import SwiftUI
import CloudKit

struct RecipesList: View {
    
    @ObservedObject var recipeManager: RecipeManager
    @FetchRequest(fetchRequest: Vote.allVotes) var allVotes
    @State private var showTabbar: Bool = true

    var body: some View {
        NavigationStack{
            VStack{
                Picker("Recipes?", selection: $recipeManager.recipeType) {
                    ForEach(RecipeType.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 10)
                
                if !recipeManager.recipes.isEmpty{
                    ScrollView{
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 0),
                                            GridItem(.flexible())]) {
                            ForEach(recipeManager.recipes, id: \.self) { recipe in
                                
                                NavigationLink {
                                    RecipeDetailsView(recipe: recipe,
                                                      recipeTitle: recipe.title!)
                                    .onAppear(perform: {
                                        withAnimation { showTabbar = false }
                                    })
                                }
                            label: { RecipeCell(recipe: recipe) }
                            }
                        }
                    }
                } else{ EmptyState(for: $recipeManager.recipeType) }
            }.navigationTitle("Matches")
                .onAppear{
                    showTabbar = true
                    recipeManager.recipeType = recipeManager.recipeType /* refreshes data */
                }
        }.toolbar(showTabbar ? .visible : .hidden, for: .tabBar)
    }
}

struct RecipeCell: View {
    var recipe: Recipe
    
    var body: some View {
        VStack(alignment: .center){
            GeometryReader { geo in
                AsyncImage(url: URL(string: recipe.imageUrl!)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        ProgressView()
                    }
                }.frame(width: geo.size.width, height: 200)
            }
            
            Text(recipe.title!)
                .multilineTextAlignment(.leading)
                .padding()
                .frame(maxWidth: .infinity,
                       maxHeight: 100,
                       alignment: .leading)
                .background(.white)
                .font(.custom("Solway-Light", size: 18))
                .foregroundColor(.black)
        }
        .frame(height: 290)
        .cornerRadius(10, corners: .allCorners)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.clear)
        )
        .shadow(radius: 10)
    }
}

struct EmptyState: View {
    @Binding var recipeType: RecipeType
    
    init(for recipeType: Binding<RecipeType>) {
        self._recipeType = recipeType
    }
    
    var body: some View {
        switch recipeType {
            
        case .likes:
            VStack(spacing: 20, content: {
                Spacer()
                Image(systemName: "heart.slash")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 100, maxHeight: 100)
                    .foregroundColor(.gray.opacity(0.6))
                
                let message = recipeType.emptyState
                Text(message)
                    .multilineTextAlignment(.center)
                    .font(.custom("Solway-Light", size: 30))
                Spacer()
            })
            
        case .matches:
            VStack(spacing: -90, content: {
                Spacer()
                let message = recipeType.emptyState
                Text(message)
                    .multilineTextAlignment(.center)
                    .font(.custom("Solway-Light", size: 30))
                Spacer()
                Image(.pointerArrow)
                    .resizable()
                    .frame(maxHeight: 350)
                    .offset(x: 40, y: 25)
            })
        }
    }
}

enum RecipeType: String, CaseIterable {
    case matches = "Matches"
    case likes   = "My Likes"
    
    var emptyState: String{
        switch self {
        case .matches:
            return "No matches, yet. \n\n Add people to your household."
        case .likes:
            return "No likes, yet. \n\n Start liking recipes."
        }
    }
}

import CoreData

struct RecipesList_Previews: PreviewProvider {
    static let entity = NSManagedObjectModel
        .mergedModel(from: nil)?
        .entitiesByName["Recipe"]
    
    static var previews: some View {
        let recipeOne = Recipe(entity: entity!, insertInto: nil)
        recipeOne.title = "Chicken Parm"
        recipeOne.imageUrl = "https://halflemons-media.s3.amazonaws.com/786.jpg"
        
        let recipeTwo = Recipe(entity: entity!, insertInto: nil)
        recipeTwo.title = "Split Pea Soup"
        recipeTwo.imageUrl = "https://halflemons-media.s3.amazonaws.com/785.jpg"
        
        let recipeThree = Recipe(entity: entity!, insertInto: nil)
        recipeThree.title = "BBQ Ribs"
        recipeThree.imageUrl = "https://halflemons-media.s3.amazonaws.com/784.jpg"
        
        let moc = DataController.shared.context
        let recipeManager = RecipeManager(managedObjectContext: moc)
        
        //        return RecipesList(recipesType: "Matches", recipes: [])
//        return RecipesList(recipeManager: recipeManager, recipesType: "Matches", recipes: [recipeOne, recipeTwo, recipeThree])
        return RecipesList(recipeManager: recipeManager)
    }
}

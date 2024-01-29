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
    
    var recipesType: String
    @State var recipes: [Recipe] = []
    
    @State private var showTabbar: Bool = true
    @State private var showHousehold: Bool = false
    
    var body: some View {
        NavigationStack{
            if !recipes.isEmpty{
                ScrollView{
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 0),
                                        GridItem(.flexible())]) {
                        ForEach(recipes, id: \.self) { recipe in
                            
                            NavigationLink {
                                RecipeDetailsView(recipe: recipe,
                                                  recipeTitle: recipe.title!)
                                .onAppear(perform: {
                                    withAnimation { showTabbar = false }
                                })
                            }
                        label: {
                            RecipeCell(recipe: recipe)
                        }
                        }
                    }
                }.navigationTitle(recipesType)
                    .onAppear(){ showTabbar = true }
            } else{
                VStack(spacing: 45, content: {
                    Image(systemName: "person.badge.plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Text("Your household is empty. \n Add people to see matches.")
                        .multilineTextAlignment(.center)
                        .font(.title3)
                    
                    Button("Add to your Household"){
                        withAnimation {
                            showTabbar = false
                            showHousehold = true
                        }
                    }
                    .font(.title)
                    .padding()
                    .foregroundColor(.black)
                    .background(.orange)
                    .cornerRadius(25, corners: .allCorners)
                })
            }
        }
        .toolbar(showTabbar ? .visible : .hidden, for: .tabBar)
        .overlay(alignment: .bottom) {
            if showHousehold{
                let dismiss = {
                    withAnimation {
                        showTabbar = true
                        showHousehold = false
                    }
                }
                Household(share: nil,
                          dismissAction: dismiss)
            }
        }
        .onAppear(perform: {
            switch recipesType {
            case "Matches":
                recipes = recipeManager.getMatches()
            case "Likes":
                let votedRecipeIds = allVotes.filter({ $0.isLiked && $0.isCurrentUser }).map({ $0.recipeId })
                recipes = recipeManager.getRecipesById(ids: votedRecipeIds) ?? []
            default:
                fatalError("###Unrecognized list of recipes.")
            }
        })
    }
}

struct RecipeCell: View {
    var recipe: Recipe
    
    var body: some View {
        VStack(alignment: .center){
            GeometryReader { geo in
                AsyncImage(url: URL(string: recipe.imageUrl!)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: 200)
                } placeholder: {
                    ProgressView()
                }
            }
            
            Text(recipe.title!)
                .multilineTextAlignment(.leading)
                .padding()
                .frame(maxWidth: .infinity,
                       maxHeight: 100,
                       alignment: .leading)
                .background(.white)
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.black)
        }
        .frame(height: 290)
        .cornerRadius(10, corners: .allCorners)
        .padding([.leading, .trailing, .bottom], 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.clear)
        )
        .shadow(radius: 20)
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
        return RecipesList(recipeManager: recipeManager, recipesType: "Matches", recipes: [recipeOne, recipeTwo, recipeThree])
    }
}

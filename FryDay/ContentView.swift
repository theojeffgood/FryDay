//
//  ContentView.swift
//  FryDay
//
//  Created by Theo Goodman on 1/17/23.
//

import SwiftUI

struct ContentView: View {
//    var recipes: [Recipe] -- this throws an error
    @State private var recipes: [Recipe] = [Recipe(recipeId: 1, title: "Chicken Cacciatore", imageUrl: "https://halflemons-media.s3.amazonaws.com/786.jpg")]
    @State private var likes: [Recipe] = []
    @State private var dislikes: [Recipe] = []
    
    @State private var showHousehold: Bool = false
    
    var body: some View {
        NavigationView {
                VStack {
                    Text("Filter")
                        .frame(maxWidth: .infinity,
                               alignment: .leading)
                        .font(.title3)
                        .foregroundColor(.gray)
                    Spacer()
                    
                    Filters(likes: $likes.wrappedValue,
                            dislikes: $dislikes.wrappedValue)
                    
                    Spacer()
                    Spacer()
                    Spacer()
                    
                    ZStack {
                        ForEach(0..<recipes.count, id: \.self) { index in
                            RecipeCardView(recipe: recipes[index]){
                                withAnimation {
                                    removeCard(at: index)
                                }
                            }
                            .stacked(at: index, in: recipes.count)
                        }
                    }
                    
                    HStack(spacing: 65) {
                        Button(action: {
                            withAnimation {
                                removeCard()
                                guard let recipe = recipes.last else { return }
                                dislikes.append(recipe)
                            }
                        }) {
                            Image(systemName: "xmark")
                                .frame(width: 90, height: 90)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(45)
                                .font(.system(size: 48, weight: .bold))
                                .shadow(radius: 25)
                        }
                        Button(action: {
                            withAnimation {
                                removeCard()
                                guard let recipe = recipes.last else { return }
                                likes.append(recipe)
                            }
                        }) {
                            Text("✓")
                                .frame(width: 90, height: 90)
                                .background(Color.green)
                                .foregroundColor(.black)
                                .cornerRadius(45)
                                .font(.system(size: 48, weight: .heavy))
                                .shadow(radius: 25)
                        }
                    }
                    .padding([.top, .bottom])
                }
                .padding()
                .navigationTitle("FryDay")
                .navigationBarItems(
                    trailing:
                        Button{
                            print("home button tapped")
                            withAnimation {
                                showHousehold = true
                            }
                        } label: {
                            Image(systemName: "house.fill")
                                .tint(.black)
                        }
                )
        }.overlay(alignment: .bottom) {
            if showHousehold{
                let dismissHousehold = {
                    withAnimation {
                        showHousehold = false
                    }
                }
                Household(dismissAction: dismissHousehold)
            }
        }
        .ignoresSafeArea()
        .accentColor(.black)
        .onAppear(){
            loadRecipes()
        }
    }
}

extension ContentView{
    func removeCard(at index: Int? = nil){
        if let index = index{
            recipes.remove(at: index)
        } else{
            let topRecipeIndex = recipes.endIndex
            recipes.remove(at: topRecipeIndex - 1)
        }
        if recipes.isEmpty{
            loadRecipes()
        }
    }
    
    func loadRecipes(){
        Task {
            let recipes = try await Webservice().load (Recipe.all)
            let shuffledRecipes = recipes.shuffled()
            self.recipes = Array(shuffledRecipes.prefix(upTo: 5))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


//MARK: -- Extensions


extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
    
    func stacked(at position: Int, in total: Int) -> some View {
        let offset = Double(total - position)
        return self.offset(x: 0, y: offset * 4)
    }
}

struct RoundedCorner: Shape {

    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

//MARK: -- Extractions

struct Filters: View {
    var likes: [Recipe] = []
    var dislikes: [Recipe] = []
    
    var body: some View{
        HStack() {
            NavigationLink(
                destination: RecipesList(recipesType: "Matches",
                                         recipes: likes),
                label: {
                    Text("❤️ Matches")
                        .frame(width: 115, height: 35)
                        .foregroundColor(.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.black, lineWidth: 1)
                        )
                })
            
            NavigationLink(
                destination: RecipesList(recipesType: "Likes",
                                         recipes: likes),
                label: {
                    Text("👍  Likes")
                        .frame(width: 115, height: 35)
                        .foregroundColor(.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.black, lineWidth: 1)
                        )
                })
            
            NavigationLink(
                destination: RecipesList(recipesType: "Dislikes",
                                         recipes: dislikes),
                label: {
                    Text("👎 Dislikes")
                        .frame(width: 115, height: 35)
                        .foregroundColor(.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.black, lineWidth: 1)
                        )
                })
            
            Spacer()
        }
    }
    
}

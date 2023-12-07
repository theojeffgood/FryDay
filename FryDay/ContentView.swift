//
//  ContentView.swift
//  FryDay
//
//  Created by Theo Goodman on 1/17/23.
//

import SwiftUI
import CloudKit

struct ContentView: View {
    
//    @ObservedObject var userManager: UserManager

    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: [NSSortDescriptor(key: "isLiked", ascending: false)],
                  predicate:        NSPredicate(format: "isShared == 1"))
    var allRecipes: FetchedResults<Recipe>
    @FetchRequest(sortDescriptors: [], predicate:
                    NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [
                        NSPredicate(format: "id = %@", UserDefaults.standard.string(forKey: "currentUserID")!),
                        NSPredicate(format: "isShared = 1")]))
    var currentUser: FetchedResults<User>
    @FetchRequest(sortDescriptors: [], predicate: NSPredicate(format: "isShared == 1"))
    var users: FetchedResults<User>
    
    @State private var recipes: [Recipe] = []
    @State private var recipeOffset: Int = 0
    @State private var showHousehold: Bool = false
    @State private var showFilters: Bool = false
    
    private let shareCoordinator = ShareCoordinator()
    private var matches: [Recipe]{
        let matches = allRecipes.filter({ $0.likesCount == users.count })
        return matches
    }
    private var likes: [Recipe]{
        if let likes = currentUser.first?.likedRecipes?.allObjects as? [Recipe]{
            return likes
        }
        return []
    }
    
    var body: some View {
        NavigationView {
            VStack {
                LikesAndMatches(matches: matches,
                        likes: likes)
                .padding(.bottom)
                Spacer()
                ZStack {
                    ForEach(recipes, id: \.self) { recipe in
                        let index = recipes.firstIndex(of: recipe)!
                        RecipeCardView(recipe: recipe,
                                       isTopRecipe: (recipe == recipes.last)){ liked, _ in
                            popRecipeStack(liked: liked, delayPop: false)
                        }
                                       .stacked(at: index, in: recipes.count)
                    }
                }
                Spacer()
                //ACTION BUTTONS
                HStack(spacing: 65) {
                    Button(action: {
                        popRecipeStack(liked: false)
                    }) {
                        Image(systemName: "xmark").rejectStyle()
                    }
                    
                    Button(action: {
                        popRecipeStack(liked: true)
                    }) {
                        Text("✓").acceptStyle()
                    }
                }
                .padding(.top, 25)
            }
            .padding()
            .navigationTitle("Fryday")
            .navigationBarItems(
                trailing:
                    HStack(content: {
                        Button{
                            withAnimation {
                                showFilters = true
                            }
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .tint(.black)
                        }
                        Button{
                            withAnimation {
                                showHousehold = true
                            }
                        } label: {
                            Image(systemName: "person.badge.plus")
                                .tint(.black)
                        }
                    })
            )
        }.overlay(alignment: .bottom) {
            if showHousehold{
                let dismiss = {
                    withAnimation {
                        showHousehold = false
                    }
                }
                Household(recipes: Array(allRecipes), users: Array(users), dismissAction: dismiss)
            }
        }
        .sheet(isPresented: $showFilters, content: {
            let dismiss = {
                withAnimation {
                    showFilters = false
                }
            }
            let applyFilter = { print("Filter was applied") }
            Filters(filterApplied: applyFilter, dismissAction: dismiss)
        })
        .ignoresSafeArea()
        .accentColor(.black)
        .onAppear(){
            loadRecipes()
        }
        
//---------SHOW JOINING-A-HOUSEHOLD ONBOARDING HERE
//        .onOpenURL { url in
//            print("referring url is: \(url)")
//        }
    }
}

extension ContentView{
    func loadRecipes(){
        if !UserDefaults.standard.bool(forKey: "appHasLaunchedBefore"),
           allRecipes.isEmpty{
            Task{
                try await Webservice(context: moc).load (Recipe.all)
                try? moc.save()
                
                recipes = Array(allRecipes.shuffled()[recipeOffset ... (recipeOffset + 2)])
                recipeOffset = 2
                
//                createNewUser()
//                UserDefaults.standard.set(true, forKey: "appHasLaunchedBefore")
            }
        } else{
            guard let currentUser = currentUser.first else { return }
            
            let unseenRecipes = allRecipes.filter { recipe in
                let userLikesRecipe = currentUser.likedRecipes?.contains(recipe) ?? false
                let userDislikesRecipe = currentUser.dislikedRecipes?.contains(recipe) ?? false
                return !userLikesRecipe && !userDislikesRecipe
            }
            if !unseenRecipes.indices.contains(recipeOffset + 2){ return }
            recipes = Array(unseenRecipes[recipeOffset ... (recipeOffset + 2)])

            recipeOffset += 2
        }
    }
    
    func popRecipeStack(liked: Bool, delayPop: Bool = true){
//1 - save the like/dislike
        handleUserPreference(recipeLiked: liked)
        checkIfMatch()
        
//2 - show swipe animation
        if delayPop{
            NotificationCenter.default.post(name: Notification.Name.swipeNotification,
                                            object: "Swiped", userInfo: ["swipeRight": liked])
        }
        
//3 - add + remove recipe
        DispatchQueue.main.asyncAfter(deadline: .now() + (delayPop ? 0.3 : 0.0)) {
            withAnimation {
                removeCard()
                addNewCard()
            }
        }
    }
    
    func handleUserPreference(recipeLiked liked: Bool){
        if let currentUser = currentUser.first,
           let recipe = recipes.last,
           let userAlreadyLikesRecipe = currentUser.likedRecipes?.contains(recipe){
            
            switch liked {
            case true:
                if !userAlreadyLikesRecipe{
                    recipe.likesCount += 1
                    
                    recipe.removeFromUserDislikes(currentUser)
                    currentUser.removeFromDislikedRecipes(recipe)
                }
                
                currentUser.likes(recipe)
                recipe.addToUser(currentUser)
            case false:
                if userAlreadyLikesRecipe{
                    recipe.likesCount -= 1
                    
                    recipe.removeFromUser(currentUser)
                    currentUser.removeFromLikedRecipes(recipe)
                }
                
                currentUser.dislikes(recipe)
                recipe.addToUserDislikes(currentUser)
            }
            
            try! moc.save() //change all try? to try! to find bugs
        }
    }
    
    func checkIfMatch(){
        if let recipe = recipes.last,
           users.count > 1,
           recipe.likesCount == users.count {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    func removeCard(){
        let topRecipeIndex = recipes.endIndex
        recipes.remove(at: topRecipeIndex - 1)
        
        if recipes.isEmpty{
            loadRecipes()
        }
    }
    
    func addNewCard(){
        guard allRecipes.indices.contains(recipeOffset) else { return }
        let newRecipe = allRecipes[recipeOffset]
        recipes.insert(newRecipe, at: 0)
        recipeOffset += 1
    }
    
    func createNewUser(){
        let user = User(context: moc)
        let userId: String = UserDefaults.standard.string(forKey: "currentUserID")!
        user.id = userId
        user.name = "Not yet set"
        user.userType = 1
        try? moc.save()
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
        return self.offset(x: 0, y: offset * 9)
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

struct LikesAndMatches: View {
    var matches: [Recipe] = []
    var likes: [Recipe] = []
    
    var body: some View{
        HStack() {
            NavigationLink(
                destination: RecipesList(recipesType: "Matches",
                                         recipes: matches),
                label: {
                    Text("❤️ Matches")
                        .frame(width: 125, height: 45)
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
                    Text("👍 Likes")
                        .frame(width: 125, height: 45)
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

extension View{
    func rejectStyle() -> some View{
        //X-MARK
        self
            .frame(width: 90, height: 90)
            .background(Color.red) // red
            .foregroundColor(.white) // white text
            .cornerRadius(45)
            .font(.system(size: 48, weight: .bold))
            .shadow(radius: 25)
    }
    
    func acceptStyle() -> some View{
        //CHECK-MARK
        self
            .frame(width: 90, height: 90)
            .background(Color.green) // green
            .foregroundColor(.black) // black text
            .cornerRadius(45)
            .font(.system(size: 48, weight: .heavy))
            .shadow(radius: 25)
    }
}

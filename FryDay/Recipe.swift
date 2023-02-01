//
//  Recipe.swift
//  FryDay
//
//  Created by Theo Goodman on 1/31/23.
//

import Foundation

struct Recipe: Hashable, Codable, Identifiable {
    var id = UUID()
    
    var recipeId: Int
    var title: String
    var imageUrl: String = ""
    var source: String = ""
    var ingredients: Array<Int> = []
    var websiteUrl: String = ""
    var cooktime: String? = nil
    var recipeStatusId: Int = 1
    
//    var url: URL = URL(string: "https://www.cnn.com")!
}

extension Recipe{
    private enum CodingKeys: String, CodingKey {
       case recipeId = "recipeId",
            title = "title",
            imageUrl = "imageUrl",
            source = "source",
            ingredients = "ingredients",
            websiteUrl = "websiteUrl",
            cooktime = "cooktime",
            recipeStatusId = "recipeStatusId"
    }
    
    init(from decoder: Decoder) throws {
//        self.init()
        
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else { fatalError() }
        recipeId = try! container.decode(Int.self, forKey: .recipeId)
        title = try! container.decode(String.self, forKey: .title)
        imageUrl = try! container.decode(String.self, forKey: .imageUrl)
        websiteUrl = try! container.decode(String.self, forKey: .websiteUrl)
        source = try! container.decode(String.self, forKey: .source)
        cooktime = try! container.decodeIfPresent(String.self, forKey: .cooktime)
        recipeStatusId = try! container.decode(Int.self, forKey: .recipeStatusId)
        
        let ingredientsList = try! container.decode(String.self, forKey: .ingredients)
        let newRecipeIngredientsList = (ingredientsList.split(separator: ";"))
        let recipeIngredientsArray = newRecipeIngredientsList.map{ Int($0)! }
        ingredients = recipeIngredientsArray
        
//        let realm = try! Realm()
//        let newRecipeIngredients = realm.objects(Food.self).filter("foodId in %@", recipeIngredientsArray)
//        ingredients.append(objectsIn: newRecipeIngredients)
    }
}
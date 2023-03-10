//
//  DataController.swift
//  FryDay
//
//  Created by Theo Goodman on 2/16/23.
//

import Foundation
import CoreData

class DataController: ObservableObject {
    
    let container = NSPersistentCloudKitContainer(name: "MealSwipe")
    
    init() {
        container.loadPersistentStores { description, error in
            if let error{
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        // Only initialize the schema when building the app with the
        // Debug build configuration.
        #if DEBUG
        do {
            // Use the container to initialize the development schema.
            try container.initializeCloudKitSchema(options: [])
        } catch {
            // Handle any errors.
        }
        #endif
        
//        SAVE CHANGES WHEN APP GOES TO BACKGROUND: https://www.donnywals.com/using-core-data-with-swiftui-2-0-and-xcode-12/
//        let center = NotificationCenter.default
//        let notification = UIApplication.willResignActiveNotification
//
//        center.addObserver(forName: notification, object: nil, queue: nil) { [weak self] _ in
//            guard let self = self else { return }
//
//            if self.container.viewContext.hasChanges {
//                try? self.container.viewContext.save()
//            }
//        }
    }
}

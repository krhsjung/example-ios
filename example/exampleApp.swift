//
//  exampleApp.swift
//  example
//
//  Created by 정희석 on 7/24/24.
//

import SwiftUI

@main
struct exampleApp: App {
    init() {
        Log.debug("Init application")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

///
//  TasksApp.swift
//  Tasks
//
//  Created by Maximilian Alexander on 8/26/21.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import SwiftUI
import DittoSwift

@main
struct TasksApp: App {
    public static var firstNameList = [
        "Henry", "William", "Geoffrey", "Jim", "Yvonne", "Jamie", "Leticia", 
        "Priscilla", "Sidney", "Nancy", "Edmund", "Bill", "Megan"
    ]

    var body: some Scene {
        WindowGroup {
            TasksListScreen()
        }
    }
}

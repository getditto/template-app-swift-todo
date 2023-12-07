///
//  ToDoApp.swift
//  ToDo
//
//  Created by Eric Turner on 11/27/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import SwiftUI
import DittoSwift

@main
struct ToDoApp: App {
    public static var firstNameList = ["Henry", "William", "Geoffrey", "Jim", "Yvonne", "Jamie", "Leticia", "Priscilla", "Sidney", "Nancy", "Edmund", "Bill", "Megan"]

    var body: some Scene {
        WindowGroup {
            TasksListScreen()
        }
    }
}

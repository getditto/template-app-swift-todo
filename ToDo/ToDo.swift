///
//  Task.swift
//  Tasks
//
//  Created by Eric Turner on 11/27/23.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import DittoSwift

struct ToDo: Codable {
    let _id: String
    let body: String
    var userId: String
    var isCompleted: Bool
    let isDeleted: Bool
    var invitationIds: [String: Bool]
}

extension ToDo: Identifiable {
    var id: String {
        return _id
    }
}

extension ToDo {
    // for previews
    init(
        body: String, isCompleted: Bool = false, userId: String = "", 
        isDeleted: Bool = false, invitationIds: [String: Bool] = [:]) 
    {
        self._id = UUID().uuidString
        self.body = body
        self.userId = userId
        self.isCompleted = isCompleted
        self.isDeleted = isDeleted
        self.invitationIds = invitationIds
    }
}

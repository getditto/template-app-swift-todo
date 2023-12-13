///
//  TaskModel.swift
//  Tasks
//
//  Created by Maximilian Alexander on 8/26/21.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import DittoSwift

struct TaskModel {
    let _id: String
    let body: String
    let userId: String
    let isCompleted: Bool
    let isSafeForEviction: Bool
    let invitationIds: [String: Bool]
    
    /// Returns instance with `QueryResultItem.value` argument
    init(_ value: [String: Any?]) {
        self._id = value["_id"] as! String
        self.body = value["body"] as! String
        self.userId = value["userId"] as? String ?? ""
        self.isCompleted = value["isCompleted"] as? Bool ?? false
        self.isSafeForEviction = value["isSafeForEviction"] as? Bool ?? false
        self.invitationIds = value["invitationIds"] as? [String:Bool] ?? [:]
    }
}

extension TaskModel: Codable {
    private static let decoder = JSONDecoder()
    
    /// Returns optional instance decoded with `QueryResultItem.jsonString()`
    static func withJson(_ json: String) -> TaskModel? {
        try? decoder.decode(Self.self, from: Data(json.utf8))
    }
}

extension TaskModel: Identifiable {
    var id: String {
        return _id
    }
}

extension TaskModel {
    // For previews
    init(
        body: String, isCompleted: Bool = false, userId: String = "", 
        isSafeForEviction: Bool = false, invitationIds: [String: Bool] = [:]) 
    {
        _id = UUID().uuidString
        self.body = body
        self.userId = userId
        self.isCompleted = isCompleted
        self.isSafeForEviction = isSafeForEviction
        self.invitationIds = invitationIds
    }
}

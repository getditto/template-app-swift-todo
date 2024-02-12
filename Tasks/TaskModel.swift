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
    
    /// Returns instance from `QueryResultItem.value
    init(_ value: [String: Any?]) {
        self._id = value["_id"] as! String
        self.body = value["body"] as! String
        self.userId = value["userId"] as? String ?? ""
        self.isCompleted = value["isCompleted"] as? Bool ?? false
        self.isSafeForEviction = value["isSafeForEviction"] as? Bool ?? false
    }
}

extension TaskModel: Codable {
    private static let decoder = JSONDecoder()
    
    /// Returns optional instance decoded from `QueryResultItem.jsonString()`
    static func withJson(_ json: String) -> TaskModel? {
        try? decoder.decode(Self.self, from: Data(json.utf8))
    }
}

extension TaskModel: Identifiable {
    
    /// Required for SwiftUI List view
    var id: String {
        return _id
    }
}

extension TaskModel: Equatable {
    
    /// Required for TaskListScreen List animation
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs._id == rhs._id
    }
}

extension TaskModel {
    
    /// Convenience for Xcode previews
    init(body: String,
         userId: String = "",
         isCompleted: Bool = false,
         isSafeForEviction: Bool = false
    ) {
        _id = UUID().uuidString
        self.body = body
        self.userId = userId
        self.isCompleted = isCompleted
        self.isSafeForEviction = isSafeForEviction
    }
}

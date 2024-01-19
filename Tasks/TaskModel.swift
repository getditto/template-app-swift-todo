///
//  TaskModel.swift
//  Tasks
//
//  Created by Maximilian Alexander on 8/26/21.
//
//  Copyright © 2023 DittoLive Incorporated. All rights reserved.

import CBORCoding
import DittoSwift

struct TaskModel {
    let _id: String
    var body: String
    var userId: String
    var isCompleted: Bool
    var isSafeForEviction: Bool
    var invitationIds: [String: Bool]    
}
 
extension TaskModel {
    
    /// Convenience initializer returns instance from `QueryResultItem.value
    init(_ value: [String: Any?]) {
        self._id = value["_id"] as! String
        self.body = value["body"] as? String ?? ""
        self.userId = value["userId"] as? String ?? ""
        self.isCompleted = value["isCompleted"] as? Bool ?? false
        self.isSafeForEviction = value["isSafeForEviction"] as? Bool ?? false
        self.invitationIds = value["invitationIds"] as? [String:Bool] ?? [:]
    }
}

extension TaskModel {
    
    /// Returns properties as key/value pairs for DQL INSERT query
    var value: [String: Any?] {
        [
            "_id": _id,
            "body": body,
            "userId": userId,
            "isCompleted": isCompleted,
            "isSafeForEviction": isSafeForEviction,
            "invitationIds": invitationIds
        ]
    }
}

extension TaskModel: Identifiable, Equatable {
    
    /// Required for SwiftUI List view
    var id: String {
        return _id
    }
    
    /// Required for TaskListScreen List animation
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

extension TaskModel {
    
    /// Convenience initializer returns model instance with default values, not from Ditto data
    static func new() -> TaskModel {
        TaskModel()
    }
}

extension TaskModel: Codable {
    static var decoder = CBORDecoder()
    
    /// Returns optional instance decoded from `QueryResultItem.cborData()`   
    init?(_ data: Data) {
        do {
            self = try Self.decoder.decode(Self.self, from: data)
        } catch {
            print("ERROR:", error.localizedDescription)
            return nil
        }        
    }
}

extension TaskModel {
    
    /// Convenience initializer with defaults for previews and instances generated for new tasks
    init(
        body: String = "", userId: String = "", isCompleted: Bool = false,  
        isSafeForEviction: Bool = false, invitationIds: [String: Bool] = [:]) 
    {
        self._id = UUID().uuidString
        self.body = body
        self.userId = userId
        self.isCompleted = isCompleted
        self.isSafeForEviction = isSafeForEviction
        self.invitationIds = invitationIds
    }
}

//
//  File.swift
//  
//
//  Created by Mohammad Azam on 6/9/20.
//

import Foundation
import Vapor
import Fluent

final class PendingFriends: Model {
    
    static let schema = "pending_friends"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "from_user")
    var fromUser: User
    
    @Parent(key: "to_user")
    var toUser: User
    
    init() {}
    
    init(fromUser: UUID, toUser: UUID) {
        self.$fromUser.id = fromUser
        self.$toUser.id = toUser
    }
    
}

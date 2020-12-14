//
//  File.swift
//  
//
//  Created by Mohammad Azam on 6/9/20.
//

import Foundation
import Vapor
import Fluent

final class UsersFriends: Model {
    
    static let schema = "users_friends"
    
        @ID(key: .id)
        var id: UUID?
        
        @Parent(key: "user")
        var user: User
        
        @Parent(key: "friend")
        var friend: User
    
    init() {}
    
    init(user: UUID, friend: UUID) {
        self.$user.id = user
        self.$friend.id = friend
    }
    
}

extension UsersFriends: Content {

}

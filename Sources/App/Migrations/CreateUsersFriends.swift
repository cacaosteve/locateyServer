//
//  File.swift
//  
//
//  Created by Mohammad Azam on 6/9/20.
//

import Foundation
import Fluent
import FluentPostgresDriver

struct CreateUsersFriends: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        
        database.schema("users_friends")
        .id()
        .field("user", .uuid, .required, .references("users", "id"))
        .field("friend", .uuid, .required, .references("users", "id"))
        .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("users_friends").delete()
    }
    
}

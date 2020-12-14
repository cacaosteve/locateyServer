//
//  File.swift
//  
//
//  Created by Mohammad Azam on 6/9/20.
//

import Foundation
import Fluent
import FluentPostgresDriver

struct CreatePendingFriends: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        
        database.schema("pending_friends")
        .id()
        .field("from_user", .uuid, .required, .references("users", "id"))
        .field("to_user", .uuid, .required, .references("users", "id"))
        .create()
        
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("pending_friends").delete()
    }
    
}

import Fluent

struct CreateUsers: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema)
            .field("id", .uuid, .identifier(auto: false))
            .field("username", .string, .required)
            .field("name", .string, .required)
            .unique(on: "username")
            .field("password_hash", .string, .required)
            .field("latitude", .double, .required)
            .field("longitude", .double, .required)
            .field("created_at", .datetime, .required)
            .field("updated_at", .datetime, .required)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(User.schema).delete()
    }
}

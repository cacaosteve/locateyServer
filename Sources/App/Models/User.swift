import Fluent
import Vapor

final class User: Model {
    
    struct Public: Content {
        let username: String
        let name: String
        let latitude: Double
        let longitude: Double
        let id: UUID
        let createdAt: Date?
        let updatedAt: Date?
    }
    
    static let schema = "users"
    
    @ID(key: "id")
    var id: UUID?
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Field(key: "latitude")
    var latitude: Double
    
    @Field(key: "longitude")
    var longitude: Double
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    @Siblings(through: UsersFriends.self, from: \.$user, to: \.$friend)
    var users: [User]
    
    init() {}
    
    init(id: UUID? = nil, username: String, passwordHash: String, latitude: Double, longitude: Double, name: String) {
        self.id = id
        self.username = username
        self.passwordHash = passwordHash
        self.latitude = latitude
        self.longitude = longitude
        self.name = name
    }
}

extension User {
    static func create(from userSignup: UserSignup) throws -> User {
        User(username: userSignup.username, passwordHash: try Bcrypt.hash(userSignup.password), latitude:userSignup.latitude, longitude:userSignup.longitude, name: userSignup.name)
    }
    
    func createToken(source: SessionSource) throws -> Token {
        let calendar = Calendar(identifier: .gregorian)
        let expiryDate = calendar.date(byAdding: .year, value: 1, to: Date())
        return try Token(userId: requireID(),
                         token: [UInt8].random(count: 16).base64, source: source, expiresAt: expiryDate)
    }
    
    func asPublic() throws -> Public {
        Public(username: username,
               name: name,
               latitude: latitude,
               longitude: longitude,
               id: try requireID(),
               createdAt: createdAt,
               updatedAt: updatedAt)
    }
}

extension User: Content {
    
}

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$username
    static let passwordHashKey = \User.$passwordHash
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}

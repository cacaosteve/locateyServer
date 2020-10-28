import Vapor
import Fluent

struct UserSignup: Content {
    let username: String
    let password: String
    let latitude: Double
    let longitude: Double
}

struct UserUpdate: Content {
    let latitude: Double
    let longitude: Double
}

struct NewSession: Content {
    let token: String
    let user: User.Public
}

extension UserSignup: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("username", as: String.self, is: !.empty)
        validations.add("password", as: String.self, is: .count(6...))
    }
}

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let usersRoute = routes.grouped("users")
        usersRoute.post("signup", use: create)
        
        //Token.authenticator???
        let tokenProtected = usersRoute.grouped(User.authenticator())
        tokenProtected.get("me", use: getMyOwnUser)
        //tokenProtected.post("update", use: update)
        
        let passwordProtected = usersRoute.grouped(User.authenticator())
        passwordProtected.post("login", use: login)
        
        //Token.authenticator???
        let tokenProtectedGetAll = usersRoute.grouped(User.authenticator())
        tokenProtectedGetAll.get("all", use: getAllHandler)
    }
    
    fileprivate func create(req: Request) throws -> EventLoopFuture<NewSession> {
        try UserSignup.validate(content: req)
        let userSignup = try req.content.decode(UserSignup.self)
        let user = try User.create(from: userSignup)
        var token: Token!
        
        return checkIfUserExists(userSignup.username, req: req).flatMap { exists in
            guard !exists else {
                return req.eventLoop.future(error: UserError.usernameTaken)
            }
            
            return user.save(on: req.db)
        }.flatMap {
            guard let newToken = try? user.createToken(source: .signup) else {
                return req.eventLoop.future(error: Abort(.internalServerError))
            }
            token = newToken
            return token.save(on: req.db)
        }.flatMapThrowing {
            NewSession(token: token.value, user: try user.asPublic())
        }
    }
    
//    fileprivate func update(req: Request) throws -> EventLoopFuture<NewSession> {
//        let user = try req.auth.require(User.self)
//        try UserUpdate.validate(content: req)
//        let userUpdate = try req.content.decode(UserUpdate.self)
//        
//    }
    
    fileprivate func login(req: Request) throws -> EventLoopFuture<NewSession> {
        let user = try req.auth.require(User.self)
        let token = try user.createToken(source: .login)
        
        return token.save(on: req.db).flatMapThrowing {
            NewSession(token: token.value, user: try user.asPublic())
        }
    }
    
    func getMyOwnUser(req: Request) throws -> User.Public {
        try req.auth.require(User.self).asPublic()
    }
    
    func getAllHandler(req: Request) throws -> EventLoopFuture<[User]> {
        return User.query(on: req.db).all()
    }
    
    private func checkIfUserExists(_ username: String, req: Request) -> EventLoopFuture<Bool> {
        User.query(on: req.db)
            .filter(\.$username == username)
            .first()
            .map { $0 != nil }
    }
}

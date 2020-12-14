import Vapor
import Fluent

struct UserSignup: Content {
    let username: String
    let password: String
    let latitude: Double
    let longitude: Double
    let name: String
}

struct UserUpdate: Content {
    let latitude: Double
    let longitude: Double
}

struct FriendRequest: Content {
    let friend: String
}

struct NewSession: Content {
    let token: String
    let user: User.Public
}

extension UserSignup: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("username", as: String.self, is: !.empty)
        validations.add("password", as: String.self, is: .count(6...))
        //        validations.add("name", as: String.self, is: .count(!.empty))
        //        validations.add("latitude", as: Double.self, is: .count(!.empty))
        //        validations.add("longitude", as: Double.self, is: .count(!.empty))
    }
}

struct UserController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let usersRoute = routes.grouped("users")
        usersRoute.post("signup", use: create)
        
        //Token.authenticator???
        let tokenProtected = usersRoute.grouped(User.authenticator())
        tokenProtected.get("me", use: getMyOwnUser)
        tokenProtected.post("update", use: update)
        
        let passwordProtected = usersRoute.grouped(User.authenticator())
        passwordProtected.post("friends", ":name", use: friend)
        
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
    
    fileprivate func update(req: Request) throws -> User {
        let myUser = try req.auth.require(User.self)
        let userUpdate = try req.content.decode(UserUpdate.self)
        
        myUser.longitude = userUpdate.longitude
        myUser.latitude = userUpdate.latitude
        _ = myUser.save(on: req.db)
        
        return myUser
    }
    
    fileprivate func login(req: Request) throws -> EventLoopFuture<NewSession> {
        let user = try req.auth.require(User.self)
        let token = try user.createToken(source: .login)
        
        return token.save(on: req.db).flatMapThrowing {
            NewSession(token: token.value, user: try user.asPublic())
        }
    }
    
    fileprivate func friend(req: Request) throws -> EventLoopFuture<User.Public> {
        guard let name = req.parameters.get("name") else {
            throw Abort(.imATeapot)
        }
        return User.query(on: req.db).filter(\.$username == name).first().unwrap(or: Abort(.notFound)).flatMapThrowing { friend in
            let user = try req.auth.require(User.self)
            
            if user.id != friend.id {
                _ = UsersFriends.query(on: req.db)
                    .filter(\.$user.$id == user.id!)
                    .filter(\.$friend.$id == friend.id!)
                    .first()
                    .flatMapThrowing { userFriend in
                        if userFriend == nil {
                            _ = UsersFriends.query(on: req.db)
                                .filter(\.$user.$id == friend.id!)
                                .filter(\.$friend.$id == user.id!)
                                .first()
                                .flatMapThrowing { userFriend2 in
                                    if userFriend2 == nil {
                                        _ = PendingFriends.query(on: req.db)
                                            .filter(\.$fromUser.$id == user.id!)
                                            .filter(\.$toUser.$id == friend.id!)
                                            .first()
                                            .flatMapThrowing { pendFriend in
                                                if pendFriend == nil {
                                                    _ = PendingFriends.query(on: req.db)
                                                        .filter(\.$fromUser.$id == friend.id!)
                                                        .filter(\.$toUser.$id == user.id!)
                                                        .first()
                                                        .flatMapThrowing { pendFriend2 in
                                                            if pendFriend2 != nil {
                                                                _ = pendFriend2?.delete(on: req.db)
                                                                
                                                                let pivot = UsersFriends(user:user.id!, friend:friend.id!)
                                                                _ = pivot.save(on: req.db)
                                                            }
                                                            else {
                                                                let pivot = PendingFriends(fromUser:user.id!, toUser:friend.id!)
                                                                _ = pivot.save(on: req.db)
                                                            }
                                                            return
                                                        }
                                                }
                                            }
                                    }
                                }
                        }
                    }
            }
            return try friend.asPublic()
        }
    }
    
    func getMyOwnUser(req: Request) throws -> User.Public {
        try req.auth.require(User.self).asPublic()
    }
    
    func getAllHandler(req: Request) throws -> EventLoopFuture<[User]> {
//        return User.query(on: req.db).all()
//    }
        let myUser = try req.auth.require(User.self)
        let users = UsersFriends.query(on: req.db).group(.or) { group in
            group.filter(\.$user.$id == myUser.id!).filter(\.$friend.$id == myUser.id!)
        }.all().flatMap { usfr -> EventLoopFuture<[User]> in
            for usfrone in usfr {
                return User.query(on: req.db).group(.or) { group in
                    return group.filter(\.$id == usfrone.user!).filter(\.$id == usfrone.friend!)
                }
            }
        }
        return users
    }
    
    
    //  return User.query(on: req.db).with(\.$users).filter(\.$id == myUser.id!).all()
    
    //        return User.query(on: req.db).group(.or) { group in
    //            group.with(\.$users).filter(\.$id == myUser.id!)
    ////                .with(\.$users).filter(\.$id == friend.id!)
    //        }.all()
    
    //        return UsersFriends.query(on: req.db).group(.or) { group in
    //            group.filter(\.$user.$id == myUser.id!).filter(\.$friend.$id == myUser.id!)
    //        }
    
    //        return UsersFriends.query(on: req.db).group(.or) { group in
    //            group.filter(\.$user.$id == myUser.id!).filter(\.$friend.$id == myUser.id!)
    //        }.all().flatMap { userFriend in
    //            userFriend.flatMap {
    //                return User.query(on: req.db)
    //                    .filter(\.$id == $0.id!)
    //                    .all()
    //            }
    //        }
    //
    //        return User.query(on: req.db).all()
    
    private func checkIfUserExists(_ username: String, req: Request) -> EventLoopFuture<Bool> {
        User.query(on: req.db)
            .filter(\.$username == username)
            .first()
            .map { $0 != nil }
    }
}

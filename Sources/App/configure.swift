import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    switch app.environment {
    case .production:
        app.databases.use(.postgres(
            hostname: Environment.get("DATABASE_HOST") ?? "ec2-54-224-175-142.compute-1.amazonaws.com",
            username: Environment.get("DATABASE_USERNAME") ?? "kitlqpasbtjita",
            password: Environment.get("DATABASE_PASSWORD") ?? "8f4317488cb19216cede65119d042e526d923509a97c3ea866946c5ac755e9ec",
            database: Environment.get("DATABASE_NAME") ?? "da2mm3hmrcqjc8"
        ), as: .psql)
    default:
        app.databases.use(.postgres(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            username: Environment.get("DATABASE_USERNAME") ?? "postgres",
            password: Environment.get("DATABASE_PASSWORD") ?? "password",
            database: Environment.get("DATABASE_NAME") ?? "locatey"
        ), as: .psql)
    }
    
    app.migrations.add(CreateUsers())
    app.migrations.add(CreateTokens())
    app.migrations.add(CreateUsersFriends())
    app.migrations.add(CreatePendingFriends())
    app.logger.logLevel = .debug
    try app.autoMigrate().wait()

    // register routes
    try routes(app)
}

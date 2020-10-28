import Fluent
import FluentPostgresDriver
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

//    app.databases.use(.postgres(
//        hostname: Environment.get("DATABASE_HOST") ?? "ec2-52-204-232-46.compute-1.amazonaws.com",
//        username: Environment.get("DATABASE_USERNAME") ?? "lbpgyxrlagqfzc",
//        password: Environment.get("DATABASE_PASSWORD") ?? "52c4b6787be2c2090fb4efe37883f944edd3c145f6823521a0aa82247237eb18",
//        database: Environment.get("DATABASE_NAME") ?? "d3gca1p92qcsv4"
//    ), as: .psql)
    
    #if DEBUG
    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        username: Environment.get("DATABASE_USERNAME") ?? "postgres",
        password: Environment.get("DATABASE_PASSWORD") ?? "password",
        database: Environment.get("DATABASE_NAME") ?? "locatey"
    ), as: .psql)
    #endif

    app.migrations.add(CreateUsers())
    app.migrations.add(CreateTokens())
    try app.autoMigrate().wait()

    // register routes
    try routes(app)
}

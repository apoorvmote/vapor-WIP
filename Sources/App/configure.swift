//import FluentSQLite
//import FluentMySQL
import Vapor
import FluentPostgreSQL

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first
    try services.register(FluentPostgreSQLProvider())

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    /// middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Configure a SQLite database
//    let sqlite = try SQLiteDatabase(storage: .memory)
//    let sqlite = try SQLiteDatabase(storage: SQLiteStorage.file(path: "db.sqlite"))

    // Configure a MySQL database
//    let databaseConfig = MySQLDatabaseConfig(hostname: "localhost", port: 3306, username: "apoorv", password: "password", database: "wip")
//    let mysql = MySQLDatabase(config: databaseConfig)
    
    // Configure a PostgreSQL database
//    let databaseConfig = PostgreSQLDatabaseConfig(hostname: "localhost", port: 5432, username: "apoorv", database: "wip", password: "password")
//    let postgres = PostgreSQLDatabase(config: databaseConfig)

    // Configure a remote database
    let hostname = Environment.get("DATABASE_HOSTNAME") ?? "localhost"
    let username = Environment.get("DATABASE_USER") ?? "apoorv"
    let databaseName = Environment.get("DATABASE_DB") ?? "wip"
    let password = Environment.get("DATABASE_PASSWORD") ?? "password"
    
    let databaseConfig = PostgreSQLDatabaseConfig(hostname: hostname, username: username, database: databaseName, password: password)
    let database = PostgreSQLDatabase(config: databaseConfig)
    
    /// Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
//    databases.add(database: sqlite, as: .sqlite)
//    databases.add(database: mysql, as: .mysql)
//    databases.add(database: postgres, as: .psql)
    databases.add(database: database, as: .psql)
    services.register(databases)

    /// Configure migrations
    var migrations = MigrationConfig()
//    migrations.add(model: Work.self, database: .sqlite)
//    migrations.add(model: Work.self, database: .mysql)
    migrations.add(model: Work.self, database: .psql)
    services.register(migrations)

}

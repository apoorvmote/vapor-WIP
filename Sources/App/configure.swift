//import FluentSQLite
//import FluentMySQL
import Vapor
import FluentPostgreSQL
import Leaf

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first
    try services.register(FluentPostgreSQLProvider())
    try services.register(LeafProvider())

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Configure a Remote database
    let database: String
    let port: Int
    
    if env == .testing {
        
        database = "wip-test"
        
        port = 5433
    }
    else {
        
        database = Environment.get("DATABASE_DB") ?? "wip"
        
        port = 5432
    }
    
    let hostname = Environment.get("DATABASE_HOSTNAME") ?? "localhost"
    let username = Environment.get("DATABASE_USER") ?? "apoorv"
    let password = Environment.get("DATABASE_PASSWORD") ?? "password"
    
    let databaseConfig = PostgreSQLDatabaseConfig(hostname: hostname, port: port, username: username, database: database, password: password)
    let postgres = PostgreSQLDatabase(config: databaseConfig)
    
    /// Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    //    databases.add(database: sqlite, as: .sqlite)
    //    databases.add(database: mysql, as: .mysql)
    databases.add(database: postgres, as: .psql)
    services.register(databases)
    
    /// Configure migrations
    var migrations = MigrationConfig()
    //    migrations.add(model: Work.self, database: .sqlite)
    //    migrations.add(model: Work.self, database: .mysql)
    migrations.add(model: Employee.self, database: .psql)
    migrations.add(model: Work.self, database: .psql)
    migrations.add(model: Category.self, database: .psql)
    migrations.add(model: WorkCategoryPivot.self, database: .psql)
    services.register(migrations)
    
    var commandConfig = CommandConfig.default()
    commandConfig.useFluentCommands()
    services.register(commandConfig)
    
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)
}

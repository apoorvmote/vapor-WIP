
import Vapor

//import FluentSQLite
//import FluentMySQL
import FluentPostgreSQL

final class Work: Codable {
    
    var id: Int?
    
    var projectName: String
    
    var percentProgress: Int
    
    init(name: String, progress: Int) {
        
        projectName = name
        
        percentProgress = progress
    }
}

//extension Work: SQLiteModel {}

//extension Work: MySQLModel {}

extension Work: PostgreSQLModel {}

extension Work: Migration {}

extension Work: Content {}

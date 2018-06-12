
import Vapor

import FluentSQLite

final class Work: Codable {
    
    var id: Int?
    
    var projectName: String
    
    var percentProgress: Int
    
    init(name: String, progress: Int) {
        
        projectName = name
        
        percentProgress = progress
    }
}

extension Work: SQLiteModel {}

extension Work: Migration {}

extension Work: Content {}

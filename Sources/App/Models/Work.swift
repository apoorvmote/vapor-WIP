
import Vapor

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

extension Work: PostgreSQLModel {}

extension Work: Migration {}

extension Work: Content {}

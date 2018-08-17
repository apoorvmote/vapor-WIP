
import Vapor

import FluentPostgreSQL

final class Employee: Content {
    
    var id: UUID?
    
    var name: String
    
    var username: String
    
    init(name: String, username: String) {
        
        self.name = name
        
        self.username = username
    }
}

extension Employee: PostgreSQLUUIDModel {}

extension Employee: Migration {}

extension Employee: Parameter {}

extension Employee {
    
    var works: Children<Employee, Work> {
        
        return children(\.employeeID)
    }
}


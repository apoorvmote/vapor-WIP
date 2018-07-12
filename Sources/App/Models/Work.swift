
import Vapor

//import FluentSQLite

//import FluentMySQL

import FluentPostgreSQL

final class Work: Codable {
    
    var id: Int?
    
    var projectName: String
    
    var percentProgress: Int
    
    var employeeID: Employee.ID
    
    init(name: String, progress: Int, employeeID: Employee.ID) {
        
        projectName = name
        
        percentProgress = progress
        
        self.employeeID = employeeID
    }
}

//extension Work: SQLiteModel {}

//extension Work: MySQLModel {}

extension Work: PostgreSQLModel {}

extension Work: Migration {
    
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        
        return Database.create(self, on: connection, closure: { (builder) in
            
            try addProperties(to: builder)
            
            builder.reference(from: \.employeeID, to: \Employee.id)
        })
    }
}

extension Work: Content {}

extension Work: Parameter {}

extension Work {
    
    var employee: Parent<Work, Employee> {
        
        return parent(\.employeeID)
    }
    
    var category: Siblings<Work, Category, WorkCategoryPivot> {
        
        return siblings()
    }
}


import Vapor

import FluentPostgreSQL

import Authentication

final class Employee: Content {
    
    var id: UUID?
    
    var name: String
    
    var username: String
    
    var password: String
    
    init(name: String, username: String, password: String) {
        
        self.name = name
        
        self.username = username
        
        self.password = password
    }
    
    final class Public: Content {
        
        var id: UUID?
        
        var name: String
        
        var username: String
        
        init(id: UUID?, name: String, username: String) {
            
            self.id = id
            
            self.name = name
            
            self.username = username
        }
    }
}

extension Employee: PostgreSQLUUIDModel {}

extension Employee: Migration {
    
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        
        return Database.create(self, on: connection, closure: { (builder) in
            
            try addProperties(to: builder)
            
            builder.unique(on: \.username)
        })
    }
}

extension Employee: Parameter {}

extension Employee {
    
    var works: Children<Employee, Work> {
        
        return children(\.employeeID)
    }
    
    func convertToPublic() -> Employee.Public {
        
        return Employee.Public(id: id, name: name, username: username)
    }
}

extension Future where T: Employee {
    
    func convertToPublic() -> Future<Employee.Public> {
        
        return self.map(to: Employee.Public.self, {$0.convertToPublic()})
    }
}

extension Employee: BasicAuthenticatable {
    
    static let usernameKey: UsernameKey = \Employee.username
    
    static let passwordKey: PasswordKey = \Employee.password
}

extension Employee: TokenAuthenticatable {
    
    typealias TokenType = AuthToken
}

struct AdminEmployee: Migration {
    
    typealias Database = PostgreSQLDatabase
    
    static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        
        guard let hashedPassword = try? BCrypt.hash("password") else { fatalError("Failed to create admin user") }
        
        let employee = Employee(name: "Admin", username: "admin", password: hashedPassword)
        
        return employee.save(on: conn).transform(to: ())
    }
    
    static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        
        return .done(on: conn)
    }
}

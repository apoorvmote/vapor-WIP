
import Vapor

import FluentPostgreSQL

import Authentication


final class AuthToken: Content {
    
    var id: UUID?
    
    var value: String
    
    var employeeID: Employee.ID
    
    init(value: String, employeeID: Employee.ID) {
        
        self.value = value
        
        self.employeeID = employeeID
    }
}

extension AuthToken: PostgreSQLUUIDModel {}

extension AuthToken: Migration {
    
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        
        return Database.create(self, on: connection, closure: { (builder) in
            
            try addProperties(to: builder)
            
            builder.reference(from: \.employeeID, to: \Employee.id)
        })
    }
}

extension AuthToken {
    
    static func generate(for employee: Employee) throws -> AuthToken {
        
        let random = try CryptoRandom().generateData(count: 16)
        
        return try AuthToken(value: random.base64EncodedString(), employeeID: employee.requireID())
    }
}

extension AuthToken: BearerAuthenticatable {
    
    static let tokenKey: TokenKey = \AuthToken.value
}

extension AuthToken: Authentication.Token {
    
    static let userIDKey: UserIDKey = \AuthToken.employeeID
    
    typealias UserType = Employee
}

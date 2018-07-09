

@testable import App

import Vapor

import FluentPostgreSQL

extension Work {
    
    static func create(projectName: String = "Logo Design", percentProgress: Int = 20, employee: Employee? = nil, conn: PostgreSQLConnection) throws -> Work {
        
        var workEmployee = employee
        
        if workEmployee == nil {
            
            workEmployee = try Employee.create(conn: conn)
        }
        
        let work = Work(name: projectName, progress: percentProgress, employeeID: workEmployee!.id!)
        
        return try work.save(on: conn).wait()
    }
}

extension Employee {
    
    static func create(name: String = "John Doe", username: String = "johndoe", conn: PostgreSQLConnection) throws -> Employee {
        
        let employee = Employee(name: name, username: username)
        
        return try employee.save(on: conn).wait()
    }
}

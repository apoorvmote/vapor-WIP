

import Vapor

import Fluent

import Crypto

struct EmployeeController: RouteCollection {
    
    func boot(router: Router) throws {
        
        let employeeRoutes = router.grouped("api", "employees")
        
//        employeeRoutes.post(Employee.self, use: createHandler)
        
        employeeRoutes.get(use: getAllHandler)
        
        employeeRoutes.get(Employee.parameter, use: getHandler)
        
//        employeeRoutes.put(Employee.self, at: Employee.parameter, use: updateHandler)
//
//        employeeRoutes.delete(Employee.parameter, use: deleteHandler)
        
        employeeRoutes.get(Employee.parameter, "works", use: getWorksHandler)
        
        let basicAuthMiddleware = Employee.basicAuthMiddleware(using: BCryptDigest())
        
        let authRoutes = employeeRoutes.grouped(basicAuthMiddleware)
        
        authRoutes.post("login", use: loginHandler)
        
        let tokenAuthMiddleware = Employee.tokenAuthMiddleware()
        
        let guardAuthMiddleware = Employee.guardAuthMiddleware()
        
        let tokenAuthRoutes = employeeRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthRoutes.post(Employee.self, use: createHandler)
        
        tokenAuthRoutes.put(Employee.self, at: Employee.parameter, use: updateHandler)
        
        tokenAuthRoutes.delete(Employee.parameter, use: deleteHandler)
    }
    
    func createHandler(_ request: Request, employee: Employee) throws -> Future<Employee.Public> {
        
        employee.password = try BCrypt.hash(employee.password)
        
        return employee.save(on: request).convertToPublic()
    }
    
    func getAllHandler(_ request: Request) throws -> Future<[Employee.Public]> {
        
        return Employee.query(on: request).decode(data: Employee.Public.self).all()
    }
    
    func getHandler(_ request: Request) throws -> Future<Employee.Public> {
        
        return try request.parameters.next(Employee.self).convertToPublic()
    }
    
    func updateHandler(_ request: Request, updatedEmployee: Employee) throws -> Future<Employee.Public> {
        
        return try request.parameters.next(Employee.self).flatMap(to: Employee.Public.self, { (employee) -> EventLoopFuture<Employee.Public> in
            
            employee.name = updatedEmployee.name
            
            employee.username = updatedEmployee.username
            
            employee.password = try BCrypt.hash(updatedEmployee.password)
            
            return employee.save(on: request).convertToPublic()
        })
    }
    
    func deleteHandler(_ request: Request) throws -> Future<HTTPStatus> {
        
        return try request.parameters.next(Employee.self).delete(on: request).transform(to: HTTPStatus.noContent)
    }
    
    func getWorksHandler(_ request: Request) throws -> Future<[Work]> {
        
        return try request.parameters.next(Employee.self).flatMap(to: [Work].self, { (employee) -> EventLoopFuture<[Work]> in
            
            return try employee.works.query(on: request).all()
        })
    }
    
    func loginHandler(_ request: Request) throws -> Future<AuthToken> {
        
        let employee = try request.requireAuthenticated(Employee.self)
        
        let authToken = try AuthToken.generate(for: employee)
        
        return authToken.save(on: request)
    }
}

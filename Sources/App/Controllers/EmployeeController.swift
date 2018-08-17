

import Vapor

import Fluent

struct EmployeeController: RouteCollection {
    
    func boot(router: Router) throws {
        
        let employeeRoute = router.grouped("api", "employees")
        
        employeeRoute.post(Employee.self, use: createHandler)
        
        employeeRoute.get(use: getAllHandler)
        
        employeeRoute.get(Employee.parameter, use: getHandler)
        
        employeeRoute.put(Employee.self, at: Employee.parameter, use: updateHandler)
        
        employeeRoute.delete(Employee.parameter, use: deleteHandler)
        
        employeeRoute.get(Employee.parameter, "works", use: getWorksHandler)
    }
    
    func createHandler(_ request: Request, employee: Employee) throws -> Future<Employee> {
        
        return employee.save(on: request)
    }
    
    func getAllHandler(_ request: Request) throws -> Future<[Employee]> {
        
        return Employee.query(on: request).all()
    }
    
    func getHandler(_ request: Request) throws -> Future<Employee> {
        
        return try request.parameters.next(Employee.self)
    }
    
    func updateHandler(_ request: Request, updatedEmployee: Employee) throws -> Future<Employee> {
        
        return try request.parameters.next(Employee.self).flatMap(to: Employee.self, { (employee) -> EventLoopFuture<Employee> in
            
            employee.name = updatedEmployee.name
            
            employee.username = updatedEmployee.username
            
            return employee.save(on: request)
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
}

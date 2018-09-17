
import Vapor

import Fluent

import Authentication

struct WorkController: RouteCollection {
    
    func boot(router: Router) throws {
        
        let workRoutes = router.grouped("api", "works")
        
        workRoutes.get(use: getAllHandler)
        
        workRoutes.get(Work.parameter, use: getHandler)
        
//        workRoutes.put(Work.self, at: Work.parameter, use: updateHandler)
        
//        workRoutes.delete(Work.parameter, use: deleteHandler)
        
        workRoutes.get("first", use: getFirstHandler)
        
        workRoutes.get("search", use: getSearchHandler)
        
        workRoutes.get("fromArray", use: getFromArrayHandler)
        
        workRoutes.get("greaterThan", use: getGreaterThanHandler)
        
        workRoutes.get("sorted", use: getSortedHandler)
        
        workRoutes.get(Work.parameter, "employee", use: getEmployeeHandler)
        
//        workRoutes.post(Work.parameter, "categories", Category.parameter, use: addCategoryHandler)
        
//        workRoutes.delete(Work.parameter, "categories", Category.parameter, use: deleteCategoryHandler)
        
        workRoutes.get(Work.parameter, "categories", use: getCategoriesHandler)

        let tokenAuthMiddleware = Employee.tokenAuthMiddleware()
        
        let guardAuthMiddleware = Employee.guardAuthMiddleware()
        
        let tokenAuthRoutes = workRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthRoutes.post(WorkCreateData.self, use: createHandler)
        
        tokenAuthRoutes.put(WorkCreateData.self, at: Work.parameter, use: updateHandler)
        
        tokenAuthRoutes.delete(Work.parameter, use: deleteHandler)
        
        tokenAuthRoutes.post(Work.parameter, "categories", Category.parameter, use: addCategoryHandler)
        
        tokenAuthRoutes.delete(Work.parameter, "categories", Category.parameter, use: deleteCategoryHandler)
        
//        let basicAuthMiddleware = Employee.basicAuthMiddleware(using: BCryptDigest())
//
//        let guardAuthMiddleware = Employee.guardAuthMiddleware()
//
//        let authRoutes = workRoutes.grouped(basicAuthMiddleware, guardAuthMiddleware)
//
//        authRoutes.post(Work.self, use: createHandler)
    }
    
    //    func createHandler(_ request: Request) throws -> Future<Work> {
    //
    //        return try request.content.decode(Work.self).flatMap(to: Work.self, { (work) -> EventLoopFuture<Work> in
    //
    //            return work.save(on: request)
    //        })
    //    }
    
    func createHandler(_ request: Request, data: WorkCreateData) throws -> Future<Work> {
        
        let employee = try request.requireAuthenticated(Employee.self)
        
        let work = try Work(name: data.projectName, progress: data.percentProgress, employeeID: employee.requireID())
        
        return work.save(on: request)
    }
    
    func getAllHandler(_ request: Request) throws -> Future<[Work]> {
        
        return Work.query(on: request).all()
    }
    
    func getHandler(_ request: Request) throws -> Future<Work> {
        
        return try request.parameters.next(Work.self)
    }
    
    func updateHandler(_ request: Request, data: WorkCreateData) throws -> Future<Work> {
        
        return try request.parameters.next(Work.self).flatMap(to: Work.self, { (work) -> EventLoopFuture<Work> in
            
            work.projectName = data.projectName
            
            work.percentProgress = data.percentProgress
            
            let employee = try request.requireAuthenticated(Employee.self)
            
            work.employeeID = try employee.requireID()
            
            return work.save(on: request)
        })
    }
    
    func deleteHandler(_ request: Request) throws -> Future<HTTPStatus> {
        
        return try request.parameters.next(Work.self).delete(on: request).transform(to: HTTPStatus.noContent)
    }
    
    func getFirstHandler(_ request: Request) throws -> Future<Work> {
        
        return Work.query(on: request).first().map(to: Work.self, { (work) -> Work in
            
            guard let work = work else {
                
                throw Abort(HTTPResponseStatus.notFound)
            }
            
            return work
        })
    }
    
    func getSearchHandler(_ request: Request) throws -> Future<[Work]> {
        
        guard let searchTerm = request.query[String.self, at: "term"] else {
            
            throw Abort(HTTPResponseStatus.badRequest)
        }
        
        return Work.query(on: request).group(.or, closure: { (or) in
            
            or.filter(\.projectName, .ilike, searchTerm)
            
            or.filter(\.percentProgress == Int(searchTerm) ?? -1)
        }).all()
    }
    
    func getFromArrayHandler(_ request: Request) throws -> Future<[Work]> {
        
        guard let array = request.query[[Int].self, at: "term"] else {
            
            throw Abort(HTTPResponseStatus.badRequest)
        }
        
        return Work.query(on: request).filter(\.percentProgress ~~ array).all()
    }
    
    func getGreaterThanHandler(_ request: Request) throws -> Future<[Work]> {
        
        guard let value = request.query[Int.self, at: "value"] else {
            
            throw Abort(HTTPResponseStatus.badRequest)
        }
        
        return Work.query(on: request).filter(\.percentProgress > value).all()
    }
    
    func getSortedHandler(_ request: Request) throws -> Future<[Work]> {
        
        return Work.query(on: request).sort(\.projectName, .ascending).all()
    }
    
    func getEmployeeHandler(_ request: Request) throws -> Future<Employee.Public> {
        
        return try request.parameters.next(Work.self).flatMap(to: Employee.Public.self, { (work) -> EventLoopFuture<Employee.Public> in
            
            return work.employee.get(on: request).convertToPublic()
        })
    }
    
    func addCategoryHandler(_ request: Request) throws -> Future<HTTPStatus> {
        
        return try flatMap(to: HTTPStatus.self, request.parameters.next(Work.self), request.parameters.next(Category.self), { (work, category) -> EventLoopFuture<HTTPStatus> in

            return work.categories.attach(category, on: request).transform(to: .created)
        })
    }
    
    func deleteCategoryHandler(_ request: Request) throws -> Future<HTTPStatus> {
        
        return try flatMap(to: HTTPStatus.self, request.parameters.next(Work.self), request.parameters.next(Category.self), { (work, category) -> EventLoopFuture<HTTPStatus> in
            
            return work.categories.detach(category, on: request).transform(to: .noContent)
        })
    }
    
    func getCategoriesHandler(_ request: Request) throws -> Future<[Category]> {
        
        return try request.parameters.next(Work.self).flatMap(to: [Category].self, { (work) -> EventLoopFuture<[Category]> in
            
            return try work.categories.query(on: request).all()
        })
    }
}

struct WorkCreateData: Content {
    
    let projectName: String
    
    let percentProgress: Int
}


import Vapor

import Fluent

struct WorkController: RouteCollection {
    
    func boot(router: Router) throws {
        
        let workRoutes = router.grouped("api", "works")
        
        //        router.post("api", "works", use: createHandler)
        
        //        workRoutes.post(use: createHandler)
        
        workRoutes.post(Work.self, use: createHandler)
        
        workRoutes.get(use: getAllHandler)
        
        workRoutes.get(Work.parameter, use: getHandler)
        
        workRoutes.put(Work.self, at: Work.parameter, use: updateHandler)
        
        workRoutes.delete(Work.parameter, use: deleteHandler)
        
        workRoutes.get("first", use: getFirstHandler)
        
        workRoutes.get("search", use: getSearchHandler)
        
        workRoutes.get("fromArray", use: getFromArrayHandler)
        
        workRoutes.get("greaterThan", use: getGreaterThanHandler)
        
        workRoutes.get("sorted", use: getSortedHandler)
        
        workRoutes.get(Work.parameter, "employee", use: getEmployeeHandler)
        
        workRoutes.post(Work.parameter, "categories", Category.parameter, use: addCategoryHandler)
        
        workRoutes.delete(Work.parameter, "categories", Category.parameter, use: deleteCategoryHandler)
        
        workRoutes.get(Work.parameter, "categories", use: getCategoriesHandler)
    }
    
    //    func createHandler(_ request: Request) throws -> Future<Work> {
    //
    //        return try request.content.decode(Work.self).flatMap(to: Work.self, { (work) -> EventLoopFuture<Work> in
    //
    //            return work.save(on: request)
    //        })
    //    }
    
    func createHandler(_ request: Request, work: Work) throws -> Future<Work> {
        
        return work.save(on: request)
    }
    
    func getAllHandler(_ request: Request) throws -> Future<[Work]> {
        
        return Work.query(on: request).all()
    }
    
    func getHandler(_ request: Request) throws -> Future<Work> {
        
        return try request.parameters.next(Work.self)
    }
    
    func updateHandler(_ request: Request, updatedWork: Work) throws -> Future<Work> {
        
        return try request.parameters.next(Work.self).flatMap(to: Work.self, { (work) -> EventLoopFuture<Work> in
            
            work.projectName = updatedWork.projectName
            
            work.percentProgress = updatedWork.percentProgress
            
            work.employeeID = updatedWork.employeeID
            
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
    
    func getEmployeeHandler(_ request: Request) throws -> Future<Employee> {
        
        return try request.parameters.next(Work.self).flatMap(to: Employee.self, { (work) -> EventLoopFuture<Employee> in
            
            return work.employee.get(on: request)
        })
    }
    
    func addCategoryHandler(_ request: Request) throws -> Future<HTTPStatus> {
        
        return try flatMap(to: HTTPStatus.self, request.parameters.next(Work.self), request.parameters.next(Category.self), { (work, category) -> EventLoopFuture<HTTPStatus> in
            
            let pivot = try WorkCategoryPivot(work.requireID(), category.requireID())
            
            return pivot.save(on: request).transform(to: HTTPStatus.created)
        })
    }
    
    func deleteCategoryHandler(_ request: Request) throws -> Future<HTTPStatus> {
        
        return try flatMap(to: HTTPStatus.self, request.parameters.next(Work.self), request.parameters.next(Category.self), { (work, category) -> EventLoopFuture<HTTPStatus> in
            
            return WorkCategoryPivot.query(on: request).group(.and, closure: { (and) in
                
                and.filter(\.workID == work.id!)
                
                and.filter(\.categoryID == category.id!)
            }).first().flatMap(to: HTTPStatus.self, { (pivot) -> EventLoopFuture<HTTPStatus> in
                
                guard let pivot = pivot else {
                    
                    throw Abort(HTTPResponseStatus.notFound)
                }
                
                return pivot.delete(on: request).transform(to: HTTPStatus.noContent)
            })
        })
    }
    
    func getCategoriesHandler(_ request: Request) throws -> Future<[Category]> {
        
        return try request.parameters.next(Work.self).flatMap(to: [Category].self, { (work) -> EventLoopFuture<[Category]> in
            
            return try work.category.query(on: request).all()
        })
    }
}


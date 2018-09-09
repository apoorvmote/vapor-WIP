
import Vapor

import Fluent

struct CategoryController: RouteCollection {
    
    func boot(router: Router) throws {
        
        let categoryRoutes = router.grouped("api", "categories")
        
//        categoriesRoutes.post(Category.self, use: createHandler)
        
        categoryRoutes.get(use: getAllHandler)
        
        categoryRoutes.get(Category.parameter, use: getHandler)
        
//        categoriesRoutes.put(Category.self, at: Category.parameter, use: updateHandler)
//
//        categoriesRoutes.delete(Category.parameter, use: deleteHandler)
        
        categoryRoutes.get(Category.parameter, "works", use: getWorksHandler)
        
        let tokenAuthMiddleware = Employee.tokenAuthMiddleware()
        
        let guardAuthMiddleware = Employee.guardAuthMiddleware()
        
        let tokenAuthRoutes = categoryRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthRoutes.post(Category.self, use: createHandler)
        
        tokenAuthRoutes.put(Category.self, at: Category.parameter, use: updateHandler)
        
        tokenAuthRoutes.delete(Category.parameter, use: deleteHandler)
    }
    
    func createHandler(_ request: Request, category: Category) throws -> Future<Category> {
        
        return category.save(on: request)
    }
    
    func getAllHandler(_ request: Request) throws -> Future<[Category]> {
        
        return Category.query(on: request).all()
    }
    
    func getHandler(_ request: Request) throws -> Future<Category> {
        
        return try request.parameters.next(Category.self)
    }
    
    func updateHandler(_ request: Request, updatedCategory: Category) throws -> Future<Category> {
        
        return try request.parameters.next(Category.self).flatMap({ (category) -> EventLoopFuture<Category> in
            
            category.name = updatedCategory.name
            
            return category.save(on: request)
        })
    }
    
    func deleteHandler(_ request: Request) throws -> Future<HTTPStatus> {
        
        return try request.parameters.next(Category.self).delete(on: request).transform(to: HTTPStatus.noContent)
    }
    
    func getWorksHandler(_ request: Request) throws -> Future<[Work]> {
        
        return try request.parameters.next(Category.self).flatMap(to: [Work].self, { (category) -> EventLoopFuture<[Work]> in
            
            return try category.works.query(on: request).all()
        })
    }
}

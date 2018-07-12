
import Vapor

import Fluent

struct CategoryController: RouteCollection {
    
    func boot(router: Router) throws {
        
        let categoriesRoute = router.grouped("api", "categories")
        
        categoriesRoute.post(Category.self, use: createHandler)
        
        categoriesRoute.get(use: getAllHandler)
        
        categoriesRoute.get(Category.parameter, use: getHandler)
        
        categoriesRoute.put(Category.self, at: Category.parameter, use: updateHandler)
        
        categoriesRoute.delete(Category.parameter, use: deleteHandler)
        
        categoriesRoute.get(Category.parameter, "works", use: getWorksHandler)
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
            
            return try category.work.query(on: request).all()
        })
    }
}


import Vapor

import FluentPostgreSQL

final class Category: Content {
    
    var id: Int?
    
    var name: String
    
    init(name: String) {
        
        self.name = name
    }
}

extension Category: PostgreSQLModel {}

extension Category: Migration {}

extension Category: Parameter {}

extension Category {
    
    var works: Siblings<Category, Work, WorkCategoryPivot> {
        
        return siblings()
    }
    
    static func addCategory(_ name: String, to work: Work, on request: Request) throws -> Future<Void> {
        
        return Category.query(on: request).filter(custom: \Category.name == name).first().flatMap(to: Void.self, { (fetchedCategory) -> EventLoopFuture<Void> in
            
            if let fetchedCategory = fetchedCategory {
                
                return work.categories.attach(fetchedCategory, on: request).transform(to: ())
            } else {
                
                let category = Category(name: name)
                
                return category.save(on: request).flatMap(to: Void.self, { (savedCategory) -> EventLoopFuture<Void> in
                    
                    return work.categories.attach(savedCategory, on: request).transform(to: ())
                })
            }
        })
    }
}

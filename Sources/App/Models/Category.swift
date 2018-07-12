
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
    
    var work: Siblings<Category, Work, WorkCategoryPivot> {
        
        return siblings()
    }
}

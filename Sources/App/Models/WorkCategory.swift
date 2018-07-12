
import FluentPostgreSQL

final class WorkCategoryPivot: PostgreSQLUUIDPivot {
    
    var id: UUID?
    
    var workID: Work.ID
    
    var categoryID: Category.ID
    
    typealias Left = Work
    
    typealias Right = Category
    
    static let leftIDKey: LeftIDKey = \.workID
    
    static let rightIDKey: RightIDKey = \.categoryID
    
    init(_ workID: Work.ID, _ categoryID: Category.ID) {
        
        self.workID = workID
        
        self.categoryID = categoryID
    }
}

extension WorkCategoryPivot: Migration {
    
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        
        return Database.create(self, on: connection, closure: { (builder) in
            
            try addProperties(to: builder)
            
            builder.reference(from: \.workID, to: \Category.id)
            
            builder.reference(from: \.categoryID, to: \Category.id)
        })
    }
}

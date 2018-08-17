
import FluentPostgreSQL

final class WorkCategoryPivot: PostgreSQLUUIDPivot, ModifiablePivot {
    
    var id: UUID?
    
    var workID: Work.ID
    
    var categoryID: Category.ID
    
    typealias Left = Work
    
    typealias Right = Category
    
    static let leftIDKey: LeftIDKey = \.workID
    
    static let rightIDKey: RightIDKey = \.categoryID
    
    init(_ work: Work, _ category: Category) throws {
        
        workID = try work.requireID()
        
        categoryID = try category.requireID()
    }
}

extension WorkCategoryPivot: Migration {
    
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        
        return Database.create(self, on: connection, closure: { (builder) in
            
            try addProperties(to: builder)
            
            builder.reference(from: \.workID, to: \Category.id, onDelete: .cascade)
            
            builder.reference(from: \.categoryID, to: \Category.id, onDelete: .cascade)
        })
    }
}

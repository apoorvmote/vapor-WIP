import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }
    
    let workController = WorkController()
    
    try router.register(collection: workController)
    
    let employeeController = EmployeeController()
    
    try router.register(collection: employeeController)
    
    let categoryController = CategoryController()
    
    try router.register(collection: categoryController)
    
    let websiteController = WebsiteController()
    
    try router.register(collection: websiteController)
}

import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }
    
    router.post(Work.self, at: "api", "works") { (request, data) -> Future<Work> in
        
        return try request.content.decode(Work.self).flatMap(to: Work.self, { (work) -> EventLoopFuture<Work> in
            
            return work.save(on: request)
        })
    }
}

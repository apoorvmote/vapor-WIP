

import App

import Vapor

import FluentPostgreSQL

extension Application {
    
    static func testable(envArgs: [String]? = nil) throws -> Application {
        
        var config = Config.default()
        
        var env = Environment.testing
        
        if let environmentArgs = envArgs {
            
            env.arguments = environmentArgs
        }
        
        var services = Services.default()
        
        try App.configure(&config, &env, &services)
        
        let app = try Application(config: config, environment: env, services: services)
        
        try App.boot(app)
        
        return app
    }
    
    static func reset() throws {
        
        let revertArgs = ["vapor", "revert", "--all", "-y"]
        
        _ = try self.testable(envArgs: revertArgs).asyncRun().wait()
        
        let migrateArgs = ["vapor", "migrate", "-y"]
        
        _ = try self.testable(envArgs: migrateArgs).asyncRun().wait()
    }
    
    func sendRequest<T>(to path: String, method: HTTPMethod = .GET, headers: HTTPHeaders = .init(), body: T?) throws -> Response where T: Content {
        
        let request = HTTPRequest(method: method, url: URL(string: path)!, headers: headers)
        
        let wrappedRequest = Request(http: request, using: self)
        
        if let body = body {
            
            try wrappedRequest.content.encode(body)
        }
        
        let responder = try self.make(Responder.self)
        
        return try responder.respond(to: wrappedRequest).wait()
    }
    
    func sendRequest<T>(to path: String, method: HTTPMethod = .GET, headers: HTTPHeaders = .init(), data: T) throws where T: Content {
        
        _ = try sendRequest(to: path, method: method, headers: headers, body: data)
    }
    
    func sendRequest(to path: String, method: HTTPMethod = .GET, headers: HTTPHeaders = .init()) throws -> Response {
        
        let emptyContent: EmptyContent? = nil
        
        return try sendRequest(to: path, method: method, headers: headers, body: emptyContent)
    }
    
    func getResponse<C, T>(to path: String, method: HTTPMethod = .GET, headers: HTTPHeaders = .init(), data: C, decodeTo type: T.Type) throws -> T where C: Content, T: Decodable {
        
        let response = try sendRequest(to: path, method: method, headers: headers, body: data)
        
        return try response.content.decode(type).wait()
    }
    
    func getResponse<T>(to path: String, method: HTTPMethod = .GET, headers: HTTPHeaders = .init(), decodeTo type: T.Type) throws -> T where T: Decodable {
        
        let response =  try sendRequest(to: path, method: method, headers: headers)
        
        return try response.content.decode(type).wait()
    }
}

struct EmptyContent: Content {}

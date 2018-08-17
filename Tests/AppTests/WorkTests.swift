

@testable import App

import Vapor

import XCTest

import FluentPostgreSQL

final class WorkTests: XCTestCase {
    
    let projectName = "Prototyping"
    
    let percentProgress = 40
    
    let worksURI = "/api/works/"
    
    var app: Application!
    
    var conn: PostgreSQLConnection!
    
    override func setUp() {
        
        try! Application.reset()
        
        app = try! Application.testable()
        
        conn = try! app.newConnection(to: .psql).wait()
    }
    
    override func tearDown() {
        
        conn.close()
    }
    
    func testWorkCanBeSavedWithAPI() throws {
        
        let employee = try Employee.create(conn: conn)
        
        let work = Work(name: projectName, progress: percentProgress, employeeID: employee.id!)
        
        let receivedWork = try app.getResponse(to: worksURI, method: .POST, headers: ["Content-Type": "application/json"], data: work, decodeTo: Work.self)
        
        let fetchedWork = try app.getResponse(to: worksURI, decodeTo: [Work].self)
        
        XCTAssertEqual(fetchedWork.count, 1)
        
        XCTAssertEqual(fetchedWork[0].projectName, projectName)
        
        XCTAssertEqual(fetchedWork[0].percentProgress, percentProgress)
        
        XCTAssertEqual(fetchedWork[0].id, receivedWork.id)
    }
    
    func testWorkCanBeRetrivedFromAPI() throws {
        
        _ = try Work.create(conn: conn)
        
        let receivedWork = try Work.create(projectName: projectName, percentProgress: percentProgress, conn: conn)
        
        _ = try Work.create(conn: conn)
        
        let fetchedWorks = try app.getResponse(to: worksURI, decodeTo: [Work].self)
        
        XCTAssertEqual(fetchedWorks.count, 3)
        
        XCTAssertEqual(fetchedWorks[1].projectName, projectName)
        
        XCTAssertEqual(fetchedWorks[1].percentProgress, percentProgress)
        
        XCTAssertEqual(fetchedWorks[1].id, receivedWork.id)
    }
    
    func testASingleWorkCanBeRetrivedFromAPI() throws {
        
        _ = try Work.create(conn: conn)
        
        let receivedWork = try Work.create(projectName: projectName, percentProgress: percentProgress, conn: conn)
        
        _ = try Work.create(conn: conn)
        
        let fetchedWork = try app.getResponse(to: "\(worksURI)\(receivedWork.id!)", decodeTo: Work.self)
        
        XCTAssertEqual(fetchedWork.projectName, projectName)
        
        XCTAssertEqual(fetchedWork.percentProgress, percentProgress)
        
        XCTAssertEqual(fetchedWork.id, receivedWork.id)
    }
    
    func testWorkCanBeUpdatedWithAPI() throws {
        
        _ = try Work.create(conn: conn)
        
        let receivedWork = try Work.create(projectName: "Marketing Research", percentProgress: 10, conn: conn)
        
        _ = try Work.create(conn: conn)
        
        let employee = try Employee.create(conn: conn)
        
        let updatedWork = Work(name: projectName, progress: percentProgress, employeeID: employee.id!)
        
        _ = try app.sendRequest(to: "\(worksURI)\(receivedWork.id!)", method: .PUT, headers: ["Content-Type": "application/json"], data: updatedWork)
        
        let fetchedWork = try app.getResponse(to: "\(worksURI)\(receivedWork.id!)", decodeTo: Work.self)
        
        XCTAssertEqual(fetchedWork.projectName, projectName)
        
        XCTAssertEqual(fetchedWork.percentProgress, percentProgress)
        
        XCTAssertEqual(fetchedWork.employeeID, employee.id)
        
        XCTAssertEqual(fetchedWork.id, receivedWork.id)
    }
    
    func testWorkCanBeDeletedWithAPI() throws {
        
        _ = try Work.create(conn: conn)
        
        let receivedWork = try Work.create(conn: conn)
        
        _ = try Work.create(conn: conn)
        
        var fetchedWork = try app.getResponse(to: worksURI, decodeTo: [Work].self)
        
        XCTAssertEqual(fetchedWork.count, 3)
        
        _ = try app.sendRequest(to: "\(worksURI)\(receivedWork.id!)", method: .DELETE)
        
        fetchedWork = try app.getResponse(to: worksURI, decodeTo: [Work].self)
        
        XCTAssertEqual(fetchedWork.count, 2)
    }
    
    func testGettingFirstWorkFromAPI() throws {
        
        let receivedWork = try Work.create(projectName: projectName, percentProgress: percentProgress, conn: conn)
        
        _ = try Work.create(conn: conn)
        
        _ = try Work.create(conn: conn)
        
        let firstWork = try app.getResponse(to: "\(worksURI)first", decodeTo: Work.self)
        
        XCTAssertEqual(firstWork.projectName, projectName)
        
        XCTAssertEqual(firstWork.percentProgress, percentProgress)
        
        XCTAssertEqual(firstWork.id, receivedWork.id)
    }
    
    func testSearchWorkFromAPI() throws {
        
        _ = try Work.create(conn: conn)
        
        let receivedWork = try Work.create(projectName: projectName, percentProgress: percentProgress, conn: conn)
        
        _ = try Work.create(conn: conn)
        
        let lcProjectName = projectName.lowercased()
        
        var fetchedWorks = try app.getResponse(to: "\(worksURI)search?term=\(lcProjectName)", decodeTo: [Work].self)
        
        XCTAssertEqual(fetchedWorks.count, 1)
        
        XCTAssertEqual(fetchedWorks[0].projectName, projectName)
        
        XCTAssertEqual(fetchedWorks[0].percentProgress, percentProgress)
        
        XCTAssertEqual(fetchedWorks[0].id, receivedWork.id)
        
        fetchedWorks = try app.getResponse(to: "\(worksURI)search?term=\(percentProgress)", decodeTo: [Work].self)
        
        XCTAssertEqual(fetchedWorks.count, 1)
        
        XCTAssertEqual(fetchedWorks[0].projectName, projectName)
        
        XCTAssertEqual(fetchedWorks[0].percentProgress, percentProgress)
        
        XCTAssertEqual(fetchedWorks[0].id, receivedWork.id)
        
        fetchedWorks = try app.getResponse(to: "\(worksURI)fromArray?term%5B%5D=\(percentProgress)", decodeTo: [Work].self)
        
        XCTAssertEqual(fetchedWorks.count, 1)
        
        XCTAssertEqual(fetchedWorks[0].projectName, projectName)
        
        XCTAssertEqual(fetchedWorks[0].percentProgress, percentProgress)
        
        XCTAssertEqual(fetchedWorks[0].id, receivedWork.id)
        
        fetchedWorks = try app.getResponse(to: "\(worksURI)greaterThan?value=30", decodeTo: [Work].self)
        
        XCTAssertEqual(fetchedWorks.count, 1)
        
        XCTAssertEqual(fetchedWorks[0].projectName, projectName)
        
        XCTAssertEqual(fetchedWorks[0].percentProgress, percentProgress)
        
        XCTAssertEqual(fetchedWorks[0].id, receivedWork.id)
    }
    
    func testSortingWorksFromAPI() throws {
        
        let names = ["c", "d", "b", "a"]
        
        for name in names {
            
            _ = try Work.create(projectName: name, conn: conn)
        }
        
        let sortedNames = names.sorted()
        
        let fetchedWorks = try app.getResponse(to: "\(worksURI)sorted", decodeTo: [Work].self)
        
        XCTAssertEqual(fetchedWorks.count, 4)
        
        XCTAssertEqual(fetchedWorks[0].projectName, sortedNames[0])
        
        XCTAssertEqual(fetchedWorks[1].projectName, sortedNames[1])
        
        XCTAssertEqual(fetchedWorks[2].projectName, sortedNames[2])
        
        XCTAssertEqual(fetchedWorks[3].projectName, sortedNames[3])
    }
    
    func testGettingWorksEmployee() throws {
        
        let employee = try Employee.create(conn: conn)
        
        let work = try Work.create(employee: employee, conn: conn)
        
        let fetchedEmployee = try app.getResponse(to: "\(worksURI)\(work.id!)/employee", decodeTo: Employee.self)
        
        XCTAssertEqual(fetchedEmployee.name, employee.name)
        
        XCTAssertEqual(fetchedEmployee.username, employee.username)
        
        XCTAssertEqual(fetchedEmployee.id, employee.id)
    }
}

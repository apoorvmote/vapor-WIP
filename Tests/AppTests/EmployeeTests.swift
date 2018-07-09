

@testable import App

import XCTest

import FluentPostgreSQL

import Vapor

final class EmployeeTests: XCTestCase {
    
    var employeeName = "Apoorv Mote"
    
    var username = "apoorvmote"
    
    var employeesURI = "/api/employees/"
    
    var app: Application!
    
    var conn: PostgreSQLConnection!
    
    override func setUp() {
        
        try! Application.revert()
        
        app = try! Application.testable()
        
        conn = try! app.newConnection(to: .psql).wait()
    }
    
    override func tearDown() {
        
        conn.close()
    }
    
    func testEmployeeCanBeSavedWithAPI() throws {
        
        let employee = Employee(name: employeeName, username: username)
        
        let receivedEmployee = try app.getResponse(to: employeesURI, method: .POST, headers: ["Content-Type": "application/json"], data: employee, decodeTo: Employee.self)
        
        let fetchedEmployees = try app.getResponse(to: employeesURI, decodeTo: [Employee].self)
        
        XCTAssertEqual(fetchedEmployees.count, 1)
        
        XCTAssertEqual(fetchedEmployees[0].name, employeeName)
        
        XCTAssertEqual(fetchedEmployees[0].username, username)
        
        XCTAssertEqual(fetchedEmployees[0].id, receivedEmployee.id)
    }
    
    func testEmployeesCanBeRetrievedFromAPI() throws {
        
        _ = try Employee.create(conn: conn)
        
        let receivedEmployee = try Employee.create(name: employeeName, username: username, conn: conn)
        
        _ = try Employee.create(conn: conn)
        
        let fetchedEmployees = try app.getResponse(to: employeesURI, decodeTo: [Employee].self)
        
        XCTAssertEqual(fetchedEmployees.count, 3)
        
        XCTAssertEqual(fetchedEmployees[1].name, employeeName)
        
        XCTAssertEqual(fetchedEmployees[1].username, username)
        
        XCTAssertEqual(fetchedEmployees[1].id, receivedEmployee.id)
        
        let fetchedEmployee = try app.getResponse(to: "\(employeesURI)\(receivedEmployee.id!)", decodeTo: Employee.self)
        
        XCTAssertEqual(fetchedEmployee.name, employeeName)
        
        XCTAssertEqual(fetchedEmployee.username, username)
        
        XCTAssertEqual(fetchedEmployee.id, receivedEmployee.id)
    }
    
    func testEmployeeCanBeUpdatedWithAPI() throws {
        
        let receivedEmployee = try Employee.create(name: "Jane Doe", username: "janedoe", conn: conn)
        
        let updatedEmployee = Employee(name: employeeName, username: username)
        
        _ = try app.sendRequest(to: "\(employeesURI)\(receivedEmployee.id!)", method: .PUT, headers: ["Content-Type": "application/json"], body: updatedEmployee)
        
        let fetchedEmployees = try app.getResponse(to: employeesURI, decodeTo: [Employee].self)
        
        XCTAssertEqual(fetchedEmployees.count, 1)
        
        XCTAssertEqual(fetchedEmployees[0].name, employeeName)
        
        XCTAssertEqual(fetchedEmployees[0].username, username)
        
        XCTAssertEqual(fetchedEmployees[0].id, receivedEmployee.id)
    }
    
    func testEmployeeCanBeDeletedWithAPI() throws {
        
        _ = try Employee.create(conn: conn)
        
        let receivedEmployee = try Employee.create(conn: conn)
        
        _ = try Employee.create(conn: conn)
        
        var fetchedEmployees = try app.getResponse(to: employeesURI, decodeTo: [Employee].self)
        
        XCTAssertEqual(fetchedEmployees.count, 3)
        
        _ = try app.sendRequest(to: "\(employeesURI)\(receivedEmployee.id!)", method: .DELETE)
        
        fetchedEmployees = try app.getResponse(to: employeesURI, decodeTo: [Employee].self)
        
        XCTAssertEqual(fetchedEmployees.count, 2)
    }
    
    func testGettingWorksFromEmployee() throws {
        
        let employee = try Employee.create(conn: conn)
        
        let work1 = try Work.create(employee: employee, conn: conn)
        
        let work2 = try Work.create(projectName: "Logo Design", percentProgress: 30, employee: employee, conn: conn)
        
        let fetchedWorks = try app.getResponse(to: "\(employeesURI)\(employee.id!)/works", decodeTo: [Work].self)
        
        XCTAssertEqual(fetchedWorks.count, 2)
        
        XCTAssertEqual(fetchedWorks[0].projectName, work1.projectName)
        
        XCTAssertEqual(fetchedWorks[0].percentProgress, work1.percentProgress)
        
        XCTAssertEqual(fetchedWorks[1].projectName, work2.projectName)
        
        XCTAssertEqual(fetchedWorks[1].percentProgress, work2.percentProgress)
    }
}

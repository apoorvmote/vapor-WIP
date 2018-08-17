
import Vapor

import Leaf

import Fluent


struct WebsiteController: RouteCollection {
    
    func boot(router: Router) throws {
        
        router.get(use: indexHandler)
        
        router.get("works", Work.parameter, use: workDetailHandler)
        
        router.get("employees", Employee.parameter, use: employeeDetailHandler)
        
        router.get("categories", Category.parameter, use: categoryDetailHandler)
        
        router.get("employees", use: allEmployeesHandler)
        
        router.get("categories", use: allCategoriesHandler)
        
        router.get("works", "create", use: createWorkHandler)
        
        router.post(createWorkData.self, at: "works", "create", use: createWorkPostHandler)
        
        router.get("works", Work.parameter, "edit", use: editWorkHandler)
        
        router.post(createWorkData.self, at: "works", Work.parameter, "edit", use: editWorkPostHandler)
        
        router.post("works", Work.parameter, "delete", use: deleteWorkHandler)
    }
    
    func indexHandler(_ request: Request) throws -> Future<View> {
        
        let context = indexContext(works: Work.query(on: request).all())
        
        return try request.view().render("index", context)
    }
    
    func workDetailHandler(_ request: Request) throws -> Future<View> {
        
        return try request.parameters.next(Work.self).flatMap(to: View.self, { (work) -> EventLoopFuture<View> in
            
            let employee = work.employee.get(on: request)
            
            let categories = try work.categories.query(on: request).all()
            
            let context = workDetailContext(title: work.projectName, work: work, employee: employee, categories: categories)
            
            return try request.view().render("workDetail", context)
        })
    }
    
    func employeeDetailHandler(_ request: Request) throws -> Future<View> {
        
        return try request.parameters.next(Employee.self).flatMap(to: View.self, { (employee) -> EventLoopFuture<View> in
            
            let works = try employee.works.query(on: request).all()
            
            let context = employeeDetailContext(title: employee.name, employee: employee, works: works)
            
            return try request.view().render("employeeDetail", context)
        })
    }
    
    func categoryDetailHandler(_ request: Request) throws -> Future<View> {
        
        return try request.parameters.next(Category.self).flatMap(to: View.self, { (category) -> EventLoopFuture<View> in
            
            let works = try category.works.query(on: request).all()
            
            let context = categoryDetailContext(title: category.name, category: category, works: works)
            
            return try request.view().render("categoryDetail", context)
        })
    }
    
    func allEmployeesHandler(_ request: Request) throws -> Future<View> {
        
        let context = allEmployeesContext(employees: Employee.query(on: request).all())
        
        return try request.view().render("allEmployees", context)
    }
    
    func allCategoriesHandler(_ request: Request) throws -> Future<View> {
        
        let context = allCategoriesContext(categories: Category.query(on: request).all())
        
        return try request.view().render("allCategories", context)
    }
    
    func createWorkHandler(_ request: Request) throws -> Future<View> {
        
        let context = createWorkContext(employees: Employee.query(on: request).all())
        
        return try request.view().render("createWork", context)
    }
    
    func createWorkPostHandler(_ request: Request, data: createWorkData) throws -> Future<Response> {
        
        let work = Work(name: data.projectName, progress: data.percentProgress, employeeID: data.employeeID)
        
        return work.save(on: request).flatMap(to: Response.self, { (savedWork) -> EventLoopFuture<Response> in
            
            guard let id = savedWork.id else { throw Abort(.internalServerError) }
            
            var categorySaves = [Future<Void>]()
            
            for name in data.categories ?? [] {
                
                try categorySaves.append(Category.addCategory(name, to: savedWork, on: request))
            }
            
            let redirect = request.redirect(to: "/works/\(id)")
            
            return categorySaves.flatten(on: request).transform(to: redirect)
        })
        
        //        return work.save(on: request).map(to: Response.self, { (work) -> Response in
        //
        //            guard let id = work.id else { throw Abort(.internalServerError) }
        //
        //            return request.redirect(to: "/works/\(id)")
        //        })
    }
    
    func editWorkHandler(_ request: Request) throws -> Future<View> {
        
        return try request.parameters.next(Work.self).flatMap(to: View.self, { (work) -> EventLoopFuture<View> in
            
            let employees = Employee.query(on: request).all()
            
            let categories = try work.categories.query(on: request).all()
            
            let context = editWorkContext(work: work, employees: employees, categories: categories)
            
            return try request.view().render("createWork", context)
        })
    }
    
    func editWorkPostHandler(_ request: Request, data: createWorkData) throws -> Future<Response> {
        
        return try request.parameters.next(Work.self).flatMap(to: Response.self, { (work) -> EventLoopFuture<Response> in
            
            work.projectName = data.projectName
            
            work.percentProgress = data.percentProgress
            
            work.employeeID = data.employeeID
            
            return work.save(on: request).flatMap(to: Response.self, { (savedWork) -> EventLoopFuture<Response> in
                
                guard let id = savedWork.id else { throw Abort(.internalServerError) }
                
                return try savedWork.categories.query(on: request).all().flatMap(to: Response.self, { (fetchedCategories) -> EventLoopFuture<Response> in
                    
                    let fetchedCategoryNames = fetchedCategories.map({$0.name})
                    
                    let fetchedSet = Set<String>(fetchedCategoryNames)
                    
                    let newSet = Set<String>(data.categories ?? [])
                    
                    let categoriesToAdd = newSet.subtracting(fetchedSet)
                    
                    let categoriesToRemove = fetchedSet.subtracting(newSet)
                    
                    var categoryResults = [Future<Void>]()
                    
                    for name in categoriesToAdd {
                        
                        categoryResults.append(try Category.addCategory(name, to: savedWork, on: request))
                    }
                    
                    for name in categoriesToRemove {
                        
                        if let category = fetchedCategories.first(where: {$0.name == name}) {
                            
                            categoryResults.append(savedWork.categories.detach(category, on: request))
                        }
                    }
                    
                    let redirect = request.redirect(to: "/works/\(id)")
                    
                    return categoryResults.flatten(on: request).transform(to: redirect)
                })
            })
        })
    }
    
    func deleteWorkHandler(_ request: Request) throws -> Future<Response> {
        
        return try request.parameters.next(Work.self).delete(on: request).transform(to: request.redirect(to: "/"))
    }
}

struct indexContext: Encodable {
    
    let title = "All Works"
    
    let works: Future<[Work]>
}

struct workDetailContext: Encodable {
    
    let title: String
    
    let work: Work
    
    let employee: Future<Employee>
    
    let categories: Future<[Category]>
}

struct employeeDetailContext: Encodable {
    
    let title: String
    
    let employee: Employee
    
    let works: Future<[Work]>
}

struct categoryDetailContext: Encodable {
    
    let title: String
    
    let category: Category
    
    let works: Future<[Work]>
}

struct allEmployeesContext: Encodable {
    
    let title = "All Employees"
    
    let employees: Future<[Employee]>
}

struct allCategoriesContext: Encodable {
    
    let title = "All Categories"
    
    let categories: Future<[Category]>
}

struct createWorkContext: Encodable {
    
    let title = "Create a Work"
    
    let employees: Future<[Employee]>
}

struct editWorkContext: Encodable {
    
    let title = "Edit Work"
    
    let work: Work
    
    let employees: Future<[Employee]>
    
    let categories: Future<[Category]>
    
    let isEditing = true
}

struct createWorkData: Content {
    
    let projectName: String
    
    let percentProgress: Int
    
    let employeeID: Employee.ID
    
    let categories: [String]?
}

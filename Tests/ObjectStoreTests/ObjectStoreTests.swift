import XCTest
@testable import ObjectStore

final class ObjectStoreTests: XCTestCase {
    func testLoadingPersistentStores() throws {
        let manager = ObjectManager(name: "TestLoading", managedObjectModel: CreateTestManagedObjectModel())
        manager.prepareWithInMemoryStore()
        
        try manager.loadStores()
        
        let expectation = self.expectation(description: "inserting and saving")
        
        let canceler = manager.inBackground({ ctx in
            let person = Person(context: ctx)
            person.firstName = "Maddie"
            person.lastName = "Schipper"
            
            if ctx.hasChanges {
                try ctx.save()
            }
        }).sink(receiveCompletion: { done in
            switch done {
            case .failure(let err):
                XCTFail(err.localizedDescription)
            case .finished:
                break
            }
            expectation.fulfill()
            
        }, receiveValue: {})
        
        self.wait(for: [expectation], timeout: 1.0)
        
        canceler.cancel()
        
        let fetch = NSFetchRequest<Person>(entityName: "Person")
        let people = try manager.viewContext.fetch(fetch)
        
        XCTAssertEqual(people.count, 1)
        XCTAssertEqual("Maddie", people.first!.firstName)
    }
}

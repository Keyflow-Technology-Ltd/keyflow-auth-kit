import XCTest
@testable import KeyflowAuthKit

final class ProductTests: XCTestCase {
    func testAudienceMapping() {
        XCTAssertEqual(KeyflowProduct.leadsflow.audience, "leadsflow")
        XCTAssertEqual(KeyflowProduct.dealsflow.audience, "dealsflow")
        XCTAssertEqual(KeyflowProduct.leaseflow.audience, "leaseflow")
    }

    func testURLSchemeMapping() {
        XCTAssertEqual(KeyflowProduct.leadsflow.urlScheme, "leadsflow")
        XCTAssertEqual(KeyflowProduct.dealsflow.urlScheme, "dealsflow")
        XCTAssertEqual(KeyflowProduct.leaseflow.urlScheme, "leaseflow")
    }
}

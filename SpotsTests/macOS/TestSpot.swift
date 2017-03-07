@testable import Spots
import XCTest

class TestSpot: XCTestCase {

  override func setUp() {
    Configuration.views.storage = [:]
    Configuration.views.defaultItem = nil
    Configuration.register(view: HeaderView.self, identifier: "Header")
    Configuration.register(view: TextView.self, identifier: "TextView")
    Configuration.register(view: FooterView.self, identifier: "Footer")
  }

  func testDefaultValues() {
    let items = [Item(title: "A"), Item(title: "B")]
    let component = Component(items: items, hybrid: true)
    let spot = Spot(component: component)

    spot.setup(CGSize(width: 100, height: 100))

    XCTAssertNotNil(spot.view)
    XCTAssertNotNil(spot.tableView)
    XCTAssertEqual(spot.items[0].size, CGSize(width: 100, height: 88))
    XCTAssertEqual(spot.items[1].size, CGSize(width: 100, height: 88))
    XCTAssertEqual(spot.view.frame.size, CGSize(width: 100, height: 180))
    let expectedContentSizeHeight: CGFloat = 180
    XCTAssertEqual(spot.view.contentSize, CGSize(width: 100, height: expectedContentSizeHeight))
  }

  func testSpotCache() {
    let item = Item(title: "test")
    let spot = Spot(cacheKey: "test-spot-cache")

    XCTAssertEqual(spot.component.items.count, 0)
    spot.append(item) {
      spot.cache()
    }

    let expectation = self.expectation(description: "Wait for cache")
    Dispatch.after(seconds: 2.5) {
      guard let cacheKey = spot.stateCache?.key else {
        XCTFail()
        return
      }

      let cachedSpot = Spot(cacheKey: cacheKey)
      XCTAssertEqual(cachedSpot.component.items[0].title, "test")
      XCTAssertEqual(cachedSpot.component.items.count, 1)
      cachedSpot.stateCache?.clear()
      expectation.fulfill()

      cachedSpot.stateCache?.clear()
    }
    waitForExpectations(timeout: 10.0, handler: nil)
  }

  func testHybridListSpotWithHeaderAndFooter() {
    let component = Component(
      header: "Header",
      footer: "Footer",
      kind: Component.Kind.list.string,
      items: [
        Item(title: "A"),
        Item(title: "B"),
        Item(title: "C"),
        Item(title: "D")
      ],
      hybrid: true
    )
    let spot = Spot(component: component)
    spot.setup(CGSize(width: 100, height: 100))

    XCTAssertEqual(spot.view.frame.size, CGSize(width: 100, height: 360))
    XCTAssertEqual(spot.view.contentSize, CGSize(width: 100, height: 360))
  }
}

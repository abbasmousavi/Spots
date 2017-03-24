#if os(OSX)
  import Foundation
#else
  import UIKit
#endif

import Tailor


/// An enum for identifing the ComponentModel kind
public enum ComponentKind: String, Equatable {
  /// The identifier for CarouselComponent
  case carousel
  /// The identifier for GridComponent
  case grid
  /// The identifier for ListComponent
  case list
  /// The identifier for RowComponent
  case row

  /// The lowercase raw value of the case
  public var string: String {
    return rawValue.lowercased()
  }

  public static func == (lhs: ComponentKind, rhs: String) -> Bool {
    return lhs.string == rhs
  }
}

/// The ComponentModel struct is used to configure a Component object
public struct ComponentModel: Mappable, Equatable, DictionaryConvertible {

  /// An enum with all the string keys used in the view model
  public enum Key: String, StringConvertible {
    case index
    case identifier
    case header
    case kind
    case meta
    case span
    case layout
    case interaction
    case items
    case size
    case width
    case height
    case footer

    public var string: String {
      return rawValue.lowercased()
    }
  }

  public var span: Double {
    get {
      return layout?.span ?? 0.0
    }
    set {
      if layout == nil {
        self.layout = Layout(span: newValue)
      } else {
        self.layout?.span = newValue
      }
    }
  }

  /// Identifier
  public var identifier: String?
  /// The index of the Item when appearing in a list, should be computed and continuously updated by the data source
  public var index: Int = 0
  /// Determines which component that should be used.
  /// Default kinds are: list, grid and carousel
  public var kind: ComponentKind = .list
  /// The header identifier
  public var header: Item?
  /// User interaction properties
  public var interaction: Interaction
  /// The footer identifier
  public var footer: Item?
  /// Layout properties
  public var layout: Layout?
  /// A collection of view models
  public var items: [Item] = [Item]()
  /// The width and height of the component, usually calculated and updated by the UI component
  public var size: CGSize? = .zero
  /// A key-value dictionary for any additional information
  public var meta = [String: Any]()

  /// A dictionary representation of the component
  public var dictionary: [String : Any] {
    return dictionary()
  }

  /// A method that creates a dictionary representation of the ComponentModel
  ///
  /// - parameter amountOfItems: An optional Int that is used to limit the amount of items that should be transformed into JSON
  ///
  /// - returns: A dictionary representation of the ComponentModel
  public func dictionary(_ amountOfItems: Int? = nil) -> [String : Any] {
    var width: CGFloat = 0
    var height: CGFloat = 0

    if let size = size {
      width = size.width
      height = size.height
    }

    let JSONItems: [[String : Any]]

    if let amountOfItems = amountOfItems {
      JSONItems = Array(items[0..<min(amountOfItems, items.count)]).map { $0.dictionary }
    } else {
      JSONItems = items.map { $0.dictionary }
    }

    var JSONComponentModels: [String : Any] = [
      Key.index.string: index,
      Key.kind.string: kind.string,
      Key.size.string: [
        Key.width.string: width,
        Key.height.string: height
      ],
      Key.items.string: JSONItems
      ]

    if let layout = layout {
      JSONComponentModels[Key.layout] = layout.dictionary
    }

    JSONComponentModels[Key.interaction] = interaction.dictionary
    JSONComponentModels[Key.identifier.string] = identifier

    JSONComponentModels[Key.header.string] = header?.dictionary
    JSONComponentModels[Key.footer.string] = footer?.dictionary

    if !meta.isEmpty {
      JSONComponentModels[Key.meta.string] = meta
    }

    return JSONComponentModels
  }

  /// Initializes a component with a JSON dictionary and maps the keys of the dictionary to its corresponding values.
  ///
  /// - parameter map: A JSON key-value dictionary.
  ///
  /// - returns: An initialized component using JSON.
  public init(_ map: [String : Any]) {
    self.identifier = map.property("identifier")
    self.kind      <- map.enum("kind")
    self.header    <- map.relation("header")
    self.footer    <- map.relation("footer")
    self.items     <- map.relations("items")
    self.meta      <- map.property("meta")

    if let layoutDictionary: [String : Any] = map.property(Layout.rootKey) {
      self.layout = Layout(layoutDictionary)
    }

    if let interactionDictionary: [String : Any] = map.property(Interaction.rootKey) {
      self.interaction = Interaction(interactionDictionary)
    } else {
      self.interaction = Interaction()
    }

    if self.layout == nil {
      self.span <- map.property("span")
    }

    let width: Double = map.resolve(keyPath: "size.width") ?? 0.0
    let height: Double = map.resolve(keyPath: "size.height") ?? 0.0
    size = CGSize(width: width, height: height)
  }

  /// Initializes a component and configures it with the provided parameters
  ///
  /// - parameter identifier: A optional string.
  /// - parameter header: Determines which header item that should be used for the model.
  /// - parameter kind: The type of ComponentModel that should be used.
  /// - parameter layout: Configures the layout properties for the model.
  /// - parameter interaction: Configures the interaction properties for the model.
  /// - parameter span: Configures the layout span for the model.
  /// - parameter items: A collection of view models
  ///
  /// - returns: An initialized component
  public init(identifier: String? = nil,
              header: Item? = nil,
              footer: Item? = nil,
              kind: ComponentKind = .list,
              layout: Layout? = nil,
              interaction: Interaction = .init(),
              span: Double? = nil,
              items: [Item] = [],
              meta: [String : Any] = [:],
              hybrid: Bool = false) {
    self.identifier = identifier
    self.kind = kind
    self.layout = layout
    self.interaction = interaction
    self.header = header
    self.footer = footer
    self.items = items
    self.meta = meta

    if let span = span, layout == nil {
      self.layout = Layout(span: span)
    }
  }

  // MARK: - Helpers

  /// A generic convenience method for resolving meta attributes
  ///
  /// - Parameter key: String
  /// - Parameter defaultValue: A generic value that works as a fallback if the key value object cannot be cast into the generic type
  ///
  /// - Returns: A generic value based on `defaultValue`, it falls back to `defaultValue` if type casting fails
  public func meta<T>(_ key: String, _ defaultValue: T) -> T {
    return meta[key] as? T ?? defaultValue
  }

  /// A convenience method for resolving meta attributes for CGFloats.
  ///
  /// - Parameter key: String.
  /// - Parameter defaultValue: A CGFloat value to be used as default if meta key is not found.
  ///
  /// - Returns: A generic value based on `defaultValue`, it falls back to `defaultValue` if type casting fails
  public func meta(_ key: String, _ defaultValue: CGFloat) -> CGFloat {
    if let doubleValue = meta[key] as? Double {
      return CGFloat(doubleValue)
    } else if let intValue = meta[key] as? Int {
      return CGFloat(intValue)
    }
    return defaultValue
  }

  /// A generic convenience method for resolving meta attributes
  ///
  /// - parameter key: String
  /// - parameter type: A generic type used for casting the meta property to a specific value or reference type
  /// - returns: An optional generic value based on `type`
  public func meta<T>(_ key: String, type: T.Type) -> T? {
    return meta[key] as? T
  }

  ///Compare two components
  ///
  /// - parameter component: A ComponentModel used for comparison
  ///
  /// - returns: A ComponentModelDiff value, see ComponentModelDiff for values.
  public func diff(model: ComponentModel) -> ComponentModelDiff {
    // Determine if the UI component is the same, used when Controller needs to replace the entire UI component
    if kind != model.kind {
      return .kind
    }
    // Determine if the unqiue identifier for the component changed
    if identifier != model.identifier {
      return .identifier
    }
    // Determine if the component layout changed, this can be used to trigger layout related processes
    if layout != model.layout {
      return .layout
    }

    // Determine if the header for the component has changed
    if !optionalCompare(lhs: header, rhs: model.header) {
      return .header
    }

    // Determine if the header for the component has changed
    if !optionalCompare(lhs: footer, rhs: model.footer) {
      return .footer
    }

    // Check if meta data for the component changed, this can be up to the developer to decide what course of action to take.
    if !(meta as NSDictionary).isEqual(to: model.meta) {
      return .meta
    }

    // Check if the items have changed
    if !(items === model.items) {
      return .items
    }

    // Check children
    let lhsChildren = items.flatMap { $0.children }
    let rhsChildren = model.items.flatMap { $0.children }

    if !(lhsChildren as NSArray).isEqual(to: rhsChildren) {
      return .items
    }

    return .none
  }

  mutating public func add(child: ComponentModel) {
    var item = Item(kind: CompositeComponent.identifier)
    item.children = [child.dictionary]
    items.append(item)
  }

  mutating public func add(children: [ComponentModel]) {
    for child in children {
      add(child: child)
    }
  }

  mutating public func add(layout: Layout) {
    self.layout = layout
  }

  mutating public func configure(with layout: Layout) -> ComponentModel {
    var copy = self
    copy.layout = layout
    return copy
  }
}

// Compare a collection of view models

/// A collection of ComponentModel Equatable implementation
/// - parameter lhs: Left hand component
/// - parameter rhs: Right hand component
///
/// - returns: A boolean value, true if both ComponentModels are equal
public func == (lhs: [ComponentModel], rhs: [ComponentModel]) -> Bool {
  var equal = lhs.count == rhs.count

  if !equal {
    return false
  }

  for (index, item) in lhs.enumerated() {
    if item != rhs[index] {
      equal = false
      break
    }
  }

  return equal
}

/// Compare two collections of ComponentModels to see if they are truly equal
///
/// - parameter lhs: Left hand component
/// - parameter rhs: Right hand component
///
/// - returns: A boolean value, true if both collections are equal
public func === (lhs: [ComponentModel], rhs: [ComponentModel]) -> Bool {
  var equal = lhs.count == rhs.count

  if !equal {
    return false
  }

  for (index, item) in lhs.enumerated() {
    if item !== rhs[index] {
      equal = false
      break
    }
  }

  return equal
}

/// Check if to collection of components are not equal
///
/// - parameter lhs: Left hand component
/// - parameter rhs: Right hand component
///
/// - returns: A boolean value, true if both ComponentModels are no equal
public func != (lhs: [ComponentModel], rhs: [ComponentModel]) -> Bool {
  return !(lhs == rhs)
}

/// Check if to collection of components are truly not equal
///
/// - parameter lhs: Left hand component
/// - parameter rhs: Right hand component
///
/// - returns: A boolean value, true if both ComponentModels are no equal
public func !== (lhs: [ComponentModel], rhs: [ComponentModel]) -> Bool {
  return !(lhs === rhs)
}

/// Compare view models

/// Check if to components are equal
///
/// - parameter lhs: Left hand component
/// - parameter rhs: Right hand component
///
/// - returns: A boolean value, true if both ComponentModels are no equal
public func == (lhs: ComponentModel, rhs: ComponentModel) -> Bool {
  guard lhs.identifier == rhs.identifier else {
    return false
  }

  let headersAreEqual = optionalCompare(lhs: lhs.header, rhs: rhs.header)
  let footersAreEqual = optionalCompare(lhs: lhs.footer, rhs: rhs.footer)

  let result = headersAreEqual == true &&
    footersAreEqual == true &&
    lhs.kind == rhs.kind &&
    lhs.layout == rhs.layout &&
    (lhs.meta as NSDictionary).isEqual(rhs.meta as NSDictionary)

  return result
}

private func optionalCompare(lhs: Item?, rhs: Item?) -> Bool {
  guard let lhsItem = lhs, let rhsItem = rhs else {
    return lhs == nil && rhs == nil
  }

  return lhsItem == rhsItem
}

/// Check if to components are truly equal
///
/// - parameter lhs: Left hand component
/// - parameter rhs: Right hand component
///
/// - returns: A boolean value, true if both ComponentModels are no equal
public func === (lhs: ComponentModel, rhs: ComponentModel) -> Bool {
  guard lhs.identifier == rhs.identifier else {
    return false
  }

  let lhsChildren = lhs.items.flatMap { $0.children.flatMap({ ComponentModel($0) }) }
  let rhsChildren = rhs.items.flatMap { $0.children.flatMap({ ComponentModel($0) }) }

  let headersAreEqual = optionalCompare(lhs: lhs.header, rhs: rhs.header)
  let footersAreEqual = optionalCompare(lhs: lhs.footer, rhs: rhs.footer)

  return headersAreEqual &&
    footersAreEqual &&
    lhs.kind == rhs.kind &&
    lhs.layout == rhs.layout &&
    (lhs.meta as NSDictionary).isEqual(rhs.meta as NSDictionary) &&
    lhsChildren === rhsChildren &&
    lhs.items == rhs.items
}

/// Check if to components are not equal
///
/// - parameter lhs: Left hand component
/// - parameter rhs: Right hand component
///
/// - returns: A boolean value, true if both ComponentModels are no equal
public func != (lhs: ComponentModel, rhs: ComponentModel) -> Bool {
  return !(lhs == rhs)
}

/// Check if to components are truly not equal
///
/// - parameter lhs: Left hand component
/// - parameter rhs: Right hand component
///
/// - returns: A boolean value, true if both ComponentModels are no equal
public func !== (lhs: ComponentModel, rhs: ComponentModel) -> Bool {
  return !(lhs === rhs)
}

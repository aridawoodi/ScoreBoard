//  This file was automatically generated and should not be edited.

#if canImport(AWSAPIPlugin)
import Foundation

public protocol GraphQLInputValue {
}

public struct GraphQLVariable {
  let name: String
  
  public init(_ name: String) {
    self.name = name
  }
}

extension GraphQLVariable: GraphQLInputValue {
}

extension JSONEncodable {
  public func evaluate(with variables: [String: JSONEncodable]?) throws -> Any {
    return jsonValue
  }
}

public typealias GraphQLMap = [String: JSONEncodable?]

extension Dictionary where Key == String, Value == JSONEncodable? {
  public var withNilValuesRemoved: Dictionary<String, JSONEncodable> {
    var filtered = Dictionary<String, JSONEncodable>(minimumCapacity: count)
    for (key, value) in self {
      if value != nil {
        filtered[key] = value
      }
    }
    return filtered
  }
}

public protocol GraphQLMapConvertible: JSONEncodable {
  var graphQLMap: GraphQLMap { get }
}

public extension GraphQLMapConvertible {
  var jsonValue: Any {
    return graphQLMap.withNilValuesRemoved.jsonValue
  }
}

public typealias GraphQLID = String

public protocol APISwiftGraphQLOperation: AnyObject {
  
  static var operationString: String { get }
  static var requestString: String { get }
  static var operationIdentifier: String? { get }
  
  var variables: GraphQLMap? { get }
  
  associatedtype Data: GraphQLSelectionSet
}

public extension APISwiftGraphQLOperation {
  static var requestString: String {
    return operationString
  }

  static var operationIdentifier: String? {
    return nil
  }

  var variables: GraphQLMap? {
    return nil
  }
}

public protocol GraphQLQuery: APISwiftGraphQLOperation {}

public protocol GraphQLMutation: APISwiftGraphQLOperation {}

public protocol GraphQLSubscription: APISwiftGraphQLOperation {}

public protocol GraphQLFragment: GraphQLSelectionSet {
  static var possibleTypes: [String] { get }
}

public typealias Snapshot = [String: Any?]

public protocol GraphQLSelectionSet: Decodable {
  static var selections: [GraphQLSelection] { get }
  
  var snapshot: Snapshot { get }
  init(snapshot: Snapshot)
}

extension GraphQLSelectionSet {
    public init(from decoder: Decoder) throws {
        if let jsonObject = try? APISwiftJSONValue(from: decoder) {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(jsonObject)
            let decodedDictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as! [String: Any]
            let optionalDictionary = decodedDictionary.mapValues { $0 as Any? }

            self.init(snapshot: optionalDictionary)
        } else {
            self.init(snapshot: [:])
        }
    }
}

enum APISwiftJSONValue: Codable {
    case array([APISwiftJSONValue])
    case boolean(Bool)
    case number(Double)
    case object([String: APISwiftJSONValue])
    case string(String)
    case null
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let value = try? container.decode([String: APISwiftJSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([APISwiftJSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .boolean(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else {
            self = .null
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .array(let value):
            try container.encode(value)
        case .boolean(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}

public protocol GraphQLSelection {
}

public struct GraphQLField: GraphQLSelection {
  let name: String
  let alias: String?
  let arguments: [String: GraphQLInputValue]?
  
  var responseKey: String {
    return alias ?? name
  }
  
  let type: GraphQLOutputType
  
  public init(_ name: String, alias: String? = nil, arguments: [String: GraphQLInputValue]? = nil, type: GraphQLOutputType) {
    self.name = name
    self.alias = alias
    
    self.arguments = arguments
    
    self.type = type
  }
}

public indirect enum GraphQLOutputType {
  case scalar(JSONDecodable.Type)
  case object([GraphQLSelection])
  case nonNull(GraphQLOutputType)
  case list(GraphQLOutputType)
  
  var namedType: GraphQLOutputType {
    switch self {
    case .nonNull(let innerType), .list(let innerType):
      return innerType.namedType
    case .scalar, .object:
      return self
    }
  }
}

public struct GraphQLBooleanCondition: GraphQLSelection {
  let variableName: String
  let inverted: Bool
  let selections: [GraphQLSelection]
  
  public init(variableName: String, inverted: Bool, selections: [GraphQLSelection]) {
    self.variableName = variableName
    self.inverted = inverted;
    self.selections = selections;
  }
}

public struct GraphQLTypeCondition: GraphQLSelection {
  let possibleTypes: [String]
  let selections: [GraphQLSelection]
  
  public init(possibleTypes: [String], selections: [GraphQLSelection]) {
    self.possibleTypes = possibleTypes
    self.selections = selections;
  }
}

public struct GraphQLFragmentSpread: GraphQLSelection {
  let fragment: GraphQLFragment.Type
  
  public init(_ fragment: GraphQLFragment.Type) {
    self.fragment = fragment
  }
}

public struct GraphQLTypeCase: GraphQLSelection {
  let variants: [String: [GraphQLSelection]]
  let `default`: [GraphQLSelection]
  
  public init(variants: [String: [GraphQLSelection]], default: [GraphQLSelection]) {
    self.variants = variants
    self.default = `default`;
  }
}

public typealias JSONObject = [String: Any]

public protocol JSONDecodable {
  init(jsonValue value: Any) throws
}

public protocol JSONEncodable: GraphQLInputValue {
  var jsonValue: Any { get }
}

public enum JSONDecodingError: Error, LocalizedError {
  case missingValue
  case nullValue
  case wrongType
  case couldNotConvert(value: Any, to: Any.Type)
  
  public var errorDescription: String? {
    switch self {
    case .missingValue:
      return "Missing value"
    case .nullValue:
      return "Unexpected null value"
    case .wrongType:
      return "Wrong type"
    case .couldNotConvert(let value, let expectedType):
      return "Could not convert \"\(value)\" to \(expectedType)"
    }
  }
}

extension String: JSONDecodable, JSONEncodable {
  public init(jsonValue value: Any) throws {
    guard let string = value as? String else {
      throw JSONDecodingError.couldNotConvert(value: value, to: String.self)
    }
    self = string
  }

  public var jsonValue: Any {
    return self
  }
}

extension Int: JSONDecodable, JSONEncodable {
  public init(jsonValue value: Any) throws {
    guard let number = value as? NSNumber else {
      throw JSONDecodingError.couldNotConvert(value: value, to: Int.self)
    }
    self = number.intValue
  }

  public var jsonValue: Any {
    return self
  }
}

extension Float: JSONDecodable, JSONEncodable {
  public init(jsonValue value: Any) throws {
    guard let number = value as? NSNumber else {
      throw JSONDecodingError.couldNotConvert(value: value, to: Float.self)
    }
    self = number.floatValue
  }

  public var jsonValue: Any {
    return self
  }
}

extension Double: JSONDecodable, JSONEncodable {
  public init(jsonValue value: Any) throws {
    guard let number = value as? NSNumber else {
      throw JSONDecodingError.couldNotConvert(value: value, to: Double.self)
    }
    self = number.doubleValue
  }

  public var jsonValue: Any {
    return self
  }
}

extension Bool: JSONDecodable, JSONEncodable {
  public init(jsonValue value: Any) throws {
    guard let bool = value as? Bool else {
        throw JSONDecodingError.couldNotConvert(value: value, to: Bool.self)
    }
    self = bool
  }

  public var jsonValue: Any {
    return self
  }
}

extension RawRepresentable where RawValue: JSONDecodable {
  public init(jsonValue value: Any) throws {
    let rawValue = try RawValue(jsonValue: value)
    if let tempSelf = Self(rawValue: rawValue) {
      self = tempSelf
    } else {
      throw JSONDecodingError.couldNotConvert(value: value, to: Self.self)
    }
  }
}

extension RawRepresentable where RawValue: JSONEncodable {
  public var jsonValue: Any {
    return rawValue.jsonValue
  }
}

extension Optional where Wrapped: JSONDecodable {
  public init(jsonValue value: Any) throws {
    if value is NSNull {
      self = .none
    } else {
      self = .some(try Wrapped(jsonValue: value))
    }
  }
}

extension Optional: JSONEncodable {
  public var jsonValue: Any {
    switch self {
    case .none:
      return NSNull()
    case .some(let wrapped as JSONEncodable):
      return wrapped.jsonValue
    default:
      fatalError("Optional is only JSONEncodable if Wrapped is")
    }
  }
}

extension Dictionary: JSONEncodable {
  public var jsonValue: Any {
    return jsonObject
  }
  
  public var jsonObject: JSONObject {
    var jsonObject = JSONObject(minimumCapacity: count)
    for (key, value) in self {
      if case let (key as String, value as JSONEncodable) = (key, value) {
        jsonObject[key] = value.jsonValue
      } else {
        fatalError("Dictionary is only JSONEncodable if Value is (and if Key is String)")
      }
    }
    return jsonObject
  }
}

extension Array: JSONEncodable {
  public var jsonValue: Any {
    return map() { element -> (Any) in
      if case let element as JSONEncodable = element {
        return element.jsonValue
      } else {
        fatalError("Array is only JSONEncodable if Element is")
      }
    }
  }
}

extension URL: JSONDecodable, JSONEncodable {
  public init(jsonValue value: Any) throws {
    guard let string = value as? String else {
      throw JSONDecodingError.couldNotConvert(value: value, to: URL.self)
    }
    self.init(string: string)!
  }

  public var jsonValue: Any {
    return self.absoluteString
  }
}

extension Dictionary {
  static func += (lhs: inout Dictionary, rhs: Dictionary) {
    lhs.merge(rhs) { (_, new) in new }
  }
}

#elseif canImport(AWSAppSync)
import AWSAppSync
#endif

public struct CreateGameInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID? = nil, gameName: String? = nil, hostUserId: String, playerIDs: [String], rounds: Int, customRules: String? = nil, finalScores: [String], gameStatus: GameStatus, winCondition: WinCondition? = nil, maxScore: Int? = nil, maxRounds: Int? = nil, createdAt: String? = nil, updatedAt: String? = nil, owner: String? = nil) {
    graphQLMap = ["id": id, "gameName": gameName, "hostUserID": hostUserId, "playerIDs": playerIDs, "rounds": rounds, "customRules": customRules, "finalScores": finalScores, "gameStatus": gameStatus, "winCondition": winCondition, "maxScore": maxScore, "maxRounds": maxRounds, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner]
  }

  public var id: GraphQLID? {
    get {
      return graphQLMap["id"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var gameName: String? {
    get {
      return graphQLMap["gameName"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gameName")
    }
  }

  public var hostUserId: String {
    get {
      return graphQLMap["hostUserID"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "hostUserID")
    }
  }

  public var playerIDs: [String] {
    get {
      return graphQLMap["playerIDs"] as! [String]
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "playerIDs")
    }
  }

  public var rounds: Int {
    get {
      return graphQLMap["rounds"] as! Int
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "rounds")
    }
  }

  public var customRules: String? {
    get {
      return graphQLMap["customRules"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "customRules")
    }
  }

  public var finalScores: [String] {
    get {
      return graphQLMap["finalScores"] as! [String]
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "finalScores")
    }
  }

  public var gameStatus: GameStatus {
    get {
      return graphQLMap["gameStatus"] as! GameStatus
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gameStatus")
    }
  }

  public var winCondition: WinCondition? {
    get {
      return graphQLMap["winCondition"] as! WinCondition?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "winCondition")
    }
  }

  public var maxScore: Int? {
    get {
      return graphQLMap["maxScore"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "maxScore")
    }
  }

  public var maxRounds: Int? {
    get {
      return graphQLMap["maxRounds"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "maxRounds")
    }
  }

  public var createdAt: String? {
    get {
      return graphQLMap["createdAt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: String? {
    get {
      return graphQLMap["updatedAt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var owner: String? {
    get {
      return graphQLMap["owner"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }
}

public enum GameStatus: RawRepresentable, Equatable, JSONDecodable, JSONEncodable {
  public typealias RawValue = String
  case active
  case completed
  case cancelled
  /// Auto generated constant for unknown enum values
  case unknown(RawValue)

  public init?(rawValue: RawValue) {
    switch rawValue {
      case "ACTIVE": self = .active
      case "COMPLETED": self = .completed
      case "CANCELLED": self = .cancelled
      default: self = .unknown(rawValue)
    }
  }

  public var rawValue: RawValue {
    switch self {
      case .active: return "ACTIVE"
      case .completed: return "COMPLETED"
      case .cancelled: return "CANCELLED"
      case .unknown(let value): return value
    }
  }

  public static func == (lhs: GameStatus, rhs: GameStatus) -> Bool {
    switch (lhs, rhs) {
      case (.active, .active): return true
      case (.completed, .completed): return true
      case (.cancelled, .cancelled): return true
      case (.unknown(let lhsValue), .unknown(let rhsValue)): return lhsValue == rhsValue
      default: return false
    }
  }
}

public enum WinCondition: RawRepresentable, Equatable, JSONDecodable, JSONEncodable {
  public typealias RawValue = String
  case highestScore
  case lowestScore
  /// Auto generated constant for unknown enum values
  case unknown(RawValue)

  public init?(rawValue: RawValue) {
    switch rawValue {
      case "HIGHEST_SCORE": self = .highestScore
      case "LOWEST_SCORE": self = .lowestScore
      default: self = .unknown(rawValue)
    }
  }

  public var rawValue: RawValue {
    switch self {
      case .highestScore: return "HIGHEST_SCORE"
      case .lowestScore: return "LOWEST_SCORE"
      case .unknown(let value): return value
    }
  }

  public static func == (lhs: WinCondition, rhs: WinCondition) -> Bool {
    switch (lhs, rhs) {
      case (.highestScore, .highestScore): return true
      case (.lowestScore, .lowestScore): return true
      case (.unknown(let lhsValue), .unknown(let rhsValue)): return lhsValue == rhsValue
      default: return false
    }
  }
}

public struct ModelGameConditionInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(gameName: ModelStringInput? = nil, hostUserId: ModelStringInput? = nil, playerIDs: ModelStringInput? = nil, rounds: ModelIntInput? = nil, customRules: ModelStringInput? = nil, finalScores: ModelStringInput? = nil, gameStatus: ModelGameStatusInput? = nil, winCondition: ModelWinConditionInput? = nil, maxScore: ModelIntInput? = nil, maxRounds: ModelIntInput? = nil, createdAt: ModelStringInput? = nil, updatedAt: ModelStringInput? = nil, owner: ModelStringInput? = nil, and: [ModelGameConditionInput?]? = nil, or: [ModelGameConditionInput?]? = nil, not: ModelGameConditionInput? = nil) {
    graphQLMap = ["gameName": gameName, "hostUserID": hostUserId, "playerIDs": playerIDs, "rounds": rounds, "customRules": customRules, "finalScores": finalScores, "gameStatus": gameStatus, "winCondition": winCondition, "maxScore": maxScore, "maxRounds": maxRounds, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner, "and": and, "or": or, "not": not]
  }

  public var gameName: ModelStringInput? {
    get {
      return graphQLMap["gameName"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gameName")
    }
  }

  public var hostUserId: ModelStringInput? {
    get {
      return graphQLMap["hostUserID"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "hostUserID")
    }
  }

  public var playerIDs: ModelStringInput? {
    get {
      return graphQLMap["playerIDs"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "playerIDs")
    }
  }

  public var rounds: ModelIntInput? {
    get {
      return graphQLMap["rounds"] as! ModelIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "rounds")
    }
  }

  public var customRules: ModelStringInput? {
    get {
      return graphQLMap["customRules"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "customRules")
    }
  }

  public var finalScores: ModelStringInput? {
    get {
      return graphQLMap["finalScores"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "finalScores")
    }
  }

  public var gameStatus: ModelGameStatusInput? {
    get {
      return graphQLMap["gameStatus"] as! ModelGameStatusInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gameStatus")
    }
  }

  public var winCondition: ModelWinConditionInput? {
    get {
      return graphQLMap["winCondition"] as! ModelWinConditionInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "winCondition")
    }
  }

  public var maxScore: ModelIntInput? {
    get {
      return graphQLMap["maxScore"] as! ModelIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "maxScore")
    }
  }

  public var maxRounds: ModelIntInput? {
    get {
      return graphQLMap["maxRounds"] as! ModelIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "maxRounds")
    }
  }

  public var createdAt: ModelStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var owner: ModelStringInput? {
    get {
      return graphQLMap["owner"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }

  public var and: [ModelGameConditionInput?]? {
    get {
      return graphQLMap["and"] as! [ModelGameConditionInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelGameConditionInput?]? {
    get {
      return graphQLMap["or"] as! [ModelGameConditionInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var not: ModelGameConditionInput? {
    get {
      return graphQLMap["not"] as! ModelGameConditionInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "not")
    }
  }
}

public struct ModelStringInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(ne: String? = nil, eq: String? = nil, le: String? = nil, lt: String? = nil, ge: String? = nil, gt: String? = nil, contains: String? = nil, notContains: String? = nil, between: [String?]? = nil, beginsWith: String? = nil, attributeExists: Bool? = nil, attributeType: ModelAttributeTypes? = nil, size: ModelSizeInput? = nil) {
    graphQLMap = ["ne": ne, "eq": eq, "le": le, "lt": lt, "ge": ge, "gt": gt, "contains": contains, "notContains": notContains, "between": between, "beginsWith": beginsWith, "attributeExists": attributeExists, "attributeType": attributeType, "size": size]
  }

  public var ne: String? {
    get {
      return graphQLMap["ne"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }

  public var eq: String? {
    get {
      return graphQLMap["eq"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var le: String? {
    get {
      return graphQLMap["le"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "le")
    }
  }

  public var lt: String? {
    get {
      return graphQLMap["lt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lt")
    }
  }

  public var ge: String? {
    get {
      return graphQLMap["ge"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ge")
    }
  }

  public var gt: String? {
    get {
      return graphQLMap["gt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gt")
    }
  }

  public var contains: String? {
    get {
      return graphQLMap["contains"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "contains")
    }
  }

  public var notContains: String? {
    get {
      return graphQLMap["notContains"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "notContains")
    }
  }

  public var between: [String?]? {
    get {
      return graphQLMap["between"] as! [String?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "between")
    }
  }

  public var beginsWith: String? {
    get {
      return graphQLMap["beginsWith"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "beginsWith")
    }
  }

  public var attributeExists: Bool? {
    get {
      return graphQLMap["attributeExists"] as! Bool?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "attributeExists")
    }
  }

  public var attributeType: ModelAttributeTypes? {
    get {
      return graphQLMap["attributeType"] as! ModelAttributeTypes?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "attributeType")
    }
  }

  public var size: ModelSizeInput? {
    get {
      return graphQLMap["size"] as! ModelSizeInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "size")
    }
  }
}

public enum ModelAttributeTypes: RawRepresentable, Equatable, JSONDecodable, JSONEncodable {
  public typealias RawValue = String
  case binary
  case binarySet
  case bool
  case list
  case map
  case number
  case numberSet
  case string
  case stringSet
  case null
  /// Auto generated constant for unknown enum values
  case unknown(RawValue)

  public init?(rawValue: RawValue) {
    switch rawValue {
      case "binary": self = .binary
      case "binarySet": self = .binarySet
      case "bool": self = .bool
      case "list": self = .list
      case "map": self = .map
      case "number": self = .number
      case "numberSet": self = .numberSet
      case "string": self = .string
      case "stringSet": self = .stringSet
      case "_null": self = .null
      default: self = .unknown(rawValue)
    }
  }

  public var rawValue: RawValue {
    switch self {
      case .binary: return "binary"
      case .binarySet: return "binarySet"
      case .bool: return "bool"
      case .list: return "list"
      case .map: return "map"
      case .number: return "number"
      case .numberSet: return "numberSet"
      case .string: return "string"
      case .stringSet: return "stringSet"
      case .null: return "_null"
      case .unknown(let value): return value
    }
  }

  public static func == (lhs: ModelAttributeTypes, rhs: ModelAttributeTypes) -> Bool {
    switch (lhs, rhs) {
      case (.binary, .binary): return true
      case (.binarySet, .binarySet): return true
      case (.bool, .bool): return true
      case (.list, .list): return true
      case (.map, .map): return true
      case (.number, .number): return true
      case (.numberSet, .numberSet): return true
      case (.string, .string): return true
      case (.stringSet, .stringSet): return true
      case (.null, .null): return true
      case (.unknown(let lhsValue), .unknown(let rhsValue)): return lhsValue == rhsValue
      default: return false
    }
  }
}

public struct ModelSizeInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(ne: Int? = nil, eq: Int? = nil, le: Int? = nil, lt: Int? = nil, ge: Int? = nil, gt: Int? = nil, between: [Int?]? = nil) {
    graphQLMap = ["ne": ne, "eq": eq, "le": le, "lt": lt, "ge": ge, "gt": gt, "between": between]
  }

  public var ne: Int? {
    get {
      return graphQLMap["ne"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }

  public var eq: Int? {
    get {
      return graphQLMap["eq"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var le: Int? {
    get {
      return graphQLMap["le"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "le")
    }
  }

  public var lt: Int? {
    get {
      return graphQLMap["lt"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lt")
    }
  }

  public var ge: Int? {
    get {
      return graphQLMap["ge"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ge")
    }
  }

  public var gt: Int? {
    get {
      return graphQLMap["gt"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gt")
    }
  }

  public var between: [Int?]? {
    get {
      return graphQLMap["between"] as! [Int?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "between")
    }
  }
}

public struct ModelIntInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(ne: Int? = nil, eq: Int? = nil, le: Int? = nil, lt: Int? = nil, ge: Int? = nil, gt: Int? = nil, between: [Int?]? = nil, attributeExists: Bool? = nil, attributeType: ModelAttributeTypes? = nil) {
    graphQLMap = ["ne": ne, "eq": eq, "le": le, "lt": lt, "ge": ge, "gt": gt, "between": between, "attributeExists": attributeExists, "attributeType": attributeType]
  }

  public var ne: Int? {
    get {
      return graphQLMap["ne"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }

  public var eq: Int? {
    get {
      return graphQLMap["eq"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var le: Int? {
    get {
      return graphQLMap["le"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "le")
    }
  }

  public var lt: Int? {
    get {
      return graphQLMap["lt"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lt")
    }
  }

  public var ge: Int? {
    get {
      return graphQLMap["ge"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ge")
    }
  }

  public var gt: Int? {
    get {
      return graphQLMap["gt"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gt")
    }
  }

  public var between: [Int?]? {
    get {
      return graphQLMap["between"] as! [Int?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "between")
    }
  }

  public var attributeExists: Bool? {
    get {
      return graphQLMap["attributeExists"] as! Bool?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "attributeExists")
    }
  }

  public var attributeType: ModelAttributeTypes? {
    get {
      return graphQLMap["attributeType"] as! ModelAttributeTypes?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "attributeType")
    }
  }
}

public struct ModelGameStatusInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(eq: GameStatus? = nil, ne: GameStatus? = nil) {
    graphQLMap = ["eq": eq, "ne": ne]
  }

  public var eq: GameStatus? {
    get {
      return graphQLMap["eq"] as! GameStatus?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var ne: GameStatus? {
    get {
      return graphQLMap["ne"] as! GameStatus?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }
}

public struct ModelWinConditionInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(eq: WinCondition? = nil, ne: WinCondition? = nil) {
    graphQLMap = ["eq": eq, "ne": ne]
  }

  public var eq: WinCondition? {
    get {
      return graphQLMap["eq"] as! WinCondition?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var ne: WinCondition? {
    get {
      return graphQLMap["ne"] as! WinCondition?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }
}

public struct UpdateGameInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID, gameName: String? = nil, hostUserId: String? = nil, playerIDs: [String]? = nil, rounds: Int? = nil, customRules: String? = nil, finalScores: [String]? = nil, gameStatus: GameStatus? = nil, winCondition: WinCondition? = nil, maxScore: Int? = nil, maxRounds: Int? = nil, createdAt: String? = nil, updatedAt: String? = nil, owner: String? = nil) {
    graphQLMap = ["id": id, "gameName": gameName, "hostUserID": hostUserId, "playerIDs": playerIDs, "rounds": rounds, "customRules": customRules, "finalScores": finalScores, "gameStatus": gameStatus, "winCondition": winCondition, "maxScore": maxScore, "maxRounds": maxRounds, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var gameName: String? {
    get {
      return graphQLMap["gameName"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gameName")
    }
  }

  public var hostUserId: String? {
    get {
      return graphQLMap["hostUserID"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "hostUserID")
    }
  }

  public var playerIDs: [String]? {
    get {
      return graphQLMap["playerIDs"] as! [String]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "playerIDs")
    }
  }

  public var rounds: Int? {
    get {
      return graphQLMap["rounds"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "rounds")
    }
  }

  public var customRules: String? {
    get {
      return graphQLMap["customRules"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "customRules")
    }
  }

  public var finalScores: [String]? {
    get {
      return graphQLMap["finalScores"] as! [String]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "finalScores")
    }
  }

  public var gameStatus: GameStatus? {
    get {
      return graphQLMap["gameStatus"] as! GameStatus?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gameStatus")
    }
  }

  public var winCondition: WinCondition? {
    get {
      return graphQLMap["winCondition"] as! WinCondition?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "winCondition")
    }
  }

  public var maxScore: Int? {
    get {
      return graphQLMap["maxScore"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "maxScore")
    }
  }

  public var maxRounds: Int? {
    get {
      return graphQLMap["maxRounds"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "maxRounds")
    }
  }

  public var createdAt: String? {
    get {
      return graphQLMap["createdAt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: String? {
    get {
      return graphQLMap["updatedAt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var owner: String? {
    get {
      return graphQLMap["owner"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }
}

public struct DeleteGameInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID) {
    graphQLMap = ["id": id]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }
}

public struct CreateScoreInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID? = nil, gameId: String, playerId: String, roundNumber: Int, score: Int, createdAt: String? = nil, updatedAt: String? = nil, owner: String? = nil) {
    graphQLMap = ["id": id, "gameID": gameId, "playerID": playerId, "roundNumber": roundNumber, "score": score, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner]
  }

  public var id: GraphQLID? {
    get {
      return graphQLMap["id"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var gameId: String {
    get {
      return graphQLMap["gameID"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gameID")
    }
  }

  public var playerId: String {
    get {
      return graphQLMap["playerID"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "playerID")
    }
  }

  public var roundNumber: Int {
    get {
      return graphQLMap["roundNumber"] as! Int
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "roundNumber")
    }
  }

  public var score: Int {
    get {
      return graphQLMap["score"] as! Int
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "score")
    }
  }

  public var createdAt: String? {
    get {
      return graphQLMap["createdAt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: String? {
    get {
      return graphQLMap["updatedAt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var owner: String? {
    get {
      return graphQLMap["owner"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }
}

public struct ModelScoreConditionInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(gameId: ModelStringInput? = nil, playerId: ModelStringInput? = nil, roundNumber: ModelIntInput? = nil, score: ModelIntInput? = nil, createdAt: ModelStringInput? = nil, updatedAt: ModelStringInput? = nil, owner: ModelStringInput? = nil, and: [ModelScoreConditionInput?]? = nil, or: [ModelScoreConditionInput?]? = nil, not: ModelScoreConditionInput? = nil) {
    graphQLMap = ["gameID": gameId, "playerID": playerId, "roundNumber": roundNumber, "score": score, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner, "and": and, "or": or, "not": not]
  }

  public var gameId: ModelStringInput? {
    get {
      return graphQLMap["gameID"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gameID")
    }
  }

  public var playerId: ModelStringInput? {
    get {
      return graphQLMap["playerID"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "playerID")
    }
  }

  public var roundNumber: ModelIntInput? {
    get {
      return graphQLMap["roundNumber"] as! ModelIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "roundNumber")
    }
  }

  public var score: ModelIntInput? {
    get {
      return graphQLMap["score"] as! ModelIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "score")
    }
  }

  public var createdAt: ModelStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var owner: ModelStringInput? {
    get {
      return graphQLMap["owner"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }

  public var and: [ModelScoreConditionInput?]? {
    get {
      return graphQLMap["and"] as! [ModelScoreConditionInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelScoreConditionInput?]? {
    get {
      return graphQLMap["or"] as! [ModelScoreConditionInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var not: ModelScoreConditionInput? {
    get {
      return graphQLMap["not"] as! ModelScoreConditionInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "not")
    }
  }
}

public struct UpdateScoreInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID, gameId: String? = nil, playerId: String? = nil, roundNumber: Int? = nil, score: Int? = nil, createdAt: String? = nil, updatedAt: String? = nil, owner: String? = nil) {
    graphQLMap = ["id": id, "gameID": gameId, "playerID": playerId, "roundNumber": roundNumber, "score": score, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var gameId: String? {
    get {
      return graphQLMap["gameID"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gameID")
    }
  }

  public var playerId: String? {
    get {
      return graphQLMap["playerID"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "playerID")
    }
  }

  public var roundNumber: Int? {
    get {
      return graphQLMap["roundNumber"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "roundNumber")
    }
  }

  public var score: Int? {
    get {
      return graphQLMap["score"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "score")
    }
  }

  public var createdAt: String? {
    get {
      return graphQLMap["createdAt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: String? {
    get {
      return graphQLMap["updatedAt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var owner: String? {
    get {
      return graphQLMap["owner"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }
}

public struct DeleteScoreInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID) {
    graphQLMap = ["id": id]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }
}

public struct CreateUserInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID? = nil, username: String, email: String, createdAt: String? = nil, updatedAt: String? = nil, owner: String? = nil) {
    graphQLMap = ["id": id, "username": username, "email": email, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner]
  }

  public var id: GraphQLID? {
    get {
      return graphQLMap["id"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var username: String {
    get {
      return graphQLMap["username"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "username")
    }
  }

  public var email: String {
    get {
      return graphQLMap["email"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "email")
    }
  }

  public var createdAt: String? {
    get {
      return graphQLMap["createdAt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: String? {
    get {
      return graphQLMap["updatedAt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var owner: String? {
    get {
      return graphQLMap["owner"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }
}

public struct ModelUserConditionInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(username: ModelStringInput? = nil, email: ModelStringInput? = nil, createdAt: ModelStringInput? = nil, updatedAt: ModelStringInput? = nil, owner: ModelStringInput? = nil, and: [ModelUserConditionInput?]? = nil, or: [ModelUserConditionInput?]? = nil, not: ModelUserConditionInput? = nil) {
    graphQLMap = ["username": username, "email": email, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner, "and": and, "or": or, "not": not]
  }

  public var username: ModelStringInput? {
    get {
      return graphQLMap["username"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "username")
    }
  }

  public var email: ModelStringInput? {
    get {
      return graphQLMap["email"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "email")
    }
  }

  public var createdAt: ModelStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var owner: ModelStringInput? {
    get {
      return graphQLMap["owner"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }

  public var and: [ModelUserConditionInput?]? {
    get {
      return graphQLMap["and"] as! [ModelUserConditionInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelUserConditionInput?]? {
    get {
      return graphQLMap["or"] as! [ModelUserConditionInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var not: ModelUserConditionInput? {
    get {
      return graphQLMap["not"] as! ModelUserConditionInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "not")
    }
  }
}

public struct UpdateUserInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID, username: String? = nil, email: String? = nil, createdAt: String? = nil, updatedAt: String? = nil, owner: String? = nil) {
    graphQLMap = ["id": id, "username": username, "email": email, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var username: String? {
    get {
      return graphQLMap["username"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "username")
    }
  }

  public var email: String? {
    get {
      return graphQLMap["email"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "email")
    }
  }

  public var createdAt: String? {
    get {
      return graphQLMap["createdAt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: String? {
    get {
      return graphQLMap["updatedAt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var owner: String? {
    get {
      return graphQLMap["owner"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }
}

public struct DeleteUserInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: GraphQLID) {
    graphQLMap = ["id": id]
  }

  public var id: GraphQLID {
    get {
      return graphQLMap["id"] as! GraphQLID
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }
}

public struct ModelGameFilterInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: ModelIDInput? = nil, gameName: ModelStringInput? = nil, hostUserId: ModelStringInput? = nil, playerIDs: ModelStringInput? = nil, rounds: ModelIntInput? = nil, customRules: ModelStringInput? = nil, finalScores: ModelStringInput? = nil, gameStatus: ModelGameStatusInput? = nil, winCondition: ModelWinConditionInput? = nil, maxScore: ModelIntInput? = nil, maxRounds: ModelIntInput? = nil, createdAt: ModelStringInput? = nil, updatedAt: ModelStringInput? = nil, owner: ModelStringInput? = nil, and: [ModelGameFilterInput?]? = nil, or: [ModelGameFilterInput?]? = nil, not: ModelGameFilterInput? = nil) {
    graphQLMap = ["id": id, "gameName": gameName, "hostUserID": hostUserId, "playerIDs": playerIDs, "rounds": rounds, "customRules": customRules, "finalScores": finalScores, "gameStatus": gameStatus, "winCondition": winCondition, "maxScore": maxScore, "maxRounds": maxRounds, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner, "and": and, "or": or, "not": not]
  }

  public var id: ModelIDInput? {
    get {
      return graphQLMap["id"] as! ModelIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var gameName: ModelStringInput? {
    get {
      return graphQLMap["gameName"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gameName")
    }
  }

  public var hostUserId: ModelStringInput? {
    get {
      return graphQLMap["hostUserID"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "hostUserID")
    }
  }

  public var playerIDs: ModelStringInput? {
    get {
      return graphQLMap["playerIDs"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "playerIDs")
    }
  }

  public var rounds: ModelIntInput? {
    get {
      return graphQLMap["rounds"] as! ModelIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "rounds")
    }
  }

  public var customRules: ModelStringInput? {
    get {
      return graphQLMap["customRules"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "customRules")
    }
  }

  public var finalScores: ModelStringInput? {
    get {
      return graphQLMap["finalScores"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "finalScores")
    }
  }

  public var gameStatus: ModelGameStatusInput? {
    get {
      return graphQLMap["gameStatus"] as! ModelGameStatusInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gameStatus")
    }
  }

  public var winCondition: ModelWinConditionInput? {
    get {
      return graphQLMap["winCondition"] as! ModelWinConditionInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "winCondition")
    }
  }

  public var maxScore: ModelIntInput? {
    get {
      return graphQLMap["maxScore"] as! ModelIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "maxScore")
    }
  }

  public var maxRounds: ModelIntInput? {
    get {
      return graphQLMap["maxRounds"] as! ModelIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "maxRounds")
    }
  }

  public var createdAt: ModelStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var owner: ModelStringInput? {
    get {
      return graphQLMap["owner"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }

  public var and: [ModelGameFilterInput?]? {
    get {
      return graphQLMap["and"] as! [ModelGameFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelGameFilterInput?]? {
    get {
      return graphQLMap["or"] as! [ModelGameFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var not: ModelGameFilterInput? {
    get {
      return graphQLMap["not"] as! ModelGameFilterInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "not")
    }
  }
}

public struct ModelIDInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(ne: GraphQLID? = nil, eq: GraphQLID? = nil, le: GraphQLID? = nil, lt: GraphQLID? = nil, ge: GraphQLID? = nil, gt: GraphQLID? = nil, contains: GraphQLID? = nil, notContains: GraphQLID? = nil, between: [GraphQLID?]? = nil, beginsWith: GraphQLID? = nil, attributeExists: Bool? = nil, attributeType: ModelAttributeTypes? = nil, size: ModelSizeInput? = nil) {
    graphQLMap = ["ne": ne, "eq": eq, "le": le, "lt": lt, "ge": ge, "gt": gt, "contains": contains, "notContains": notContains, "between": between, "beginsWith": beginsWith, "attributeExists": attributeExists, "attributeType": attributeType, "size": size]
  }

  public var ne: GraphQLID? {
    get {
      return graphQLMap["ne"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }

  public var eq: GraphQLID? {
    get {
      return graphQLMap["eq"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var le: GraphQLID? {
    get {
      return graphQLMap["le"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "le")
    }
  }

  public var lt: GraphQLID? {
    get {
      return graphQLMap["lt"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lt")
    }
  }

  public var ge: GraphQLID? {
    get {
      return graphQLMap["ge"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ge")
    }
  }

  public var gt: GraphQLID? {
    get {
      return graphQLMap["gt"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gt")
    }
  }

  public var contains: GraphQLID? {
    get {
      return graphQLMap["contains"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "contains")
    }
  }

  public var notContains: GraphQLID? {
    get {
      return graphQLMap["notContains"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "notContains")
    }
  }

  public var between: [GraphQLID?]? {
    get {
      return graphQLMap["between"] as! [GraphQLID?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "between")
    }
  }

  public var beginsWith: GraphQLID? {
    get {
      return graphQLMap["beginsWith"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "beginsWith")
    }
  }

  public var attributeExists: Bool? {
    get {
      return graphQLMap["attributeExists"] as! Bool?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "attributeExists")
    }
  }

  public var attributeType: ModelAttributeTypes? {
    get {
      return graphQLMap["attributeType"] as! ModelAttributeTypes?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "attributeType")
    }
  }

  public var size: ModelSizeInput? {
    get {
      return graphQLMap["size"] as! ModelSizeInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "size")
    }
  }
}

public struct ModelScoreFilterInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: ModelIDInput? = nil, gameId: ModelStringInput? = nil, playerId: ModelStringInput? = nil, roundNumber: ModelIntInput? = nil, score: ModelIntInput? = nil, createdAt: ModelStringInput? = nil, updatedAt: ModelStringInput? = nil, owner: ModelStringInput? = nil, and: [ModelScoreFilterInput?]? = nil, or: [ModelScoreFilterInput?]? = nil, not: ModelScoreFilterInput? = nil) {
    graphQLMap = ["id": id, "gameID": gameId, "playerID": playerId, "roundNumber": roundNumber, "score": score, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner, "and": and, "or": or, "not": not]
  }

  public var id: ModelIDInput? {
    get {
      return graphQLMap["id"] as! ModelIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var gameId: ModelStringInput? {
    get {
      return graphQLMap["gameID"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gameID")
    }
  }

  public var playerId: ModelStringInput? {
    get {
      return graphQLMap["playerID"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "playerID")
    }
  }

  public var roundNumber: ModelIntInput? {
    get {
      return graphQLMap["roundNumber"] as! ModelIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "roundNumber")
    }
  }

  public var score: ModelIntInput? {
    get {
      return graphQLMap["score"] as! ModelIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "score")
    }
  }

  public var createdAt: ModelStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var owner: ModelStringInput? {
    get {
      return graphQLMap["owner"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }

  public var and: [ModelScoreFilterInput?]? {
    get {
      return graphQLMap["and"] as! [ModelScoreFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelScoreFilterInput?]? {
    get {
      return graphQLMap["or"] as! [ModelScoreFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var not: ModelScoreFilterInput? {
    get {
      return graphQLMap["not"] as! ModelScoreFilterInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "not")
    }
  }
}

public struct ModelUserFilterInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: ModelIDInput? = nil, username: ModelStringInput? = nil, email: ModelStringInput? = nil, createdAt: ModelStringInput? = nil, updatedAt: ModelStringInput? = nil, owner: ModelStringInput? = nil, and: [ModelUserFilterInput?]? = nil, or: [ModelUserFilterInput?]? = nil, not: ModelUserFilterInput? = nil) {
    graphQLMap = ["id": id, "username": username, "email": email, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner, "and": and, "or": or, "not": not]
  }

  public var id: ModelIDInput? {
    get {
      return graphQLMap["id"] as! ModelIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var username: ModelStringInput? {
    get {
      return graphQLMap["username"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "username")
    }
  }

  public var email: ModelStringInput? {
    get {
      return graphQLMap["email"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "email")
    }
  }

  public var createdAt: ModelStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var owner: ModelStringInput? {
    get {
      return graphQLMap["owner"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }

  public var and: [ModelUserFilterInput?]? {
    get {
      return graphQLMap["and"] as! [ModelUserFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelUserFilterInput?]? {
    get {
      return graphQLMap["or"] as! [ModelUserFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var not: ModelUserFilterInput? {
    get {
      return graphQLMap["not"] as! ModelUserFilterInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "not")
    }
  }
}

public struct ModelSubscriptionGameFilterInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: ModelSubscriptionIDInput? = nil, gameName: ModelSubscriptionStringInput? = nil, hostUserId: ModelSubscriptionStringInput? = nil, playerIDs: ModelSubscriptionStringInput? = nil, rounds: ModelSubscriptionIntInput? = nil, customRules: ModelSubscriptionStringInput? = nil, finalScores: ModelSubscriptionStringInput? = nil, gameStatus: ModelSubscriptionStringInput? = nil, winCondition: ModelSubscriptionStringInput? = nil, maxScore: ModelSubscriptionIntInput? = nil, maxRounds: ModelSubscriptionIntInput? = nil, createdAt: ModelSubscriptionStringInput? = nil, updatedAt: ModelSubscriptionStringInput? = nil, and: [ModelSubscriptionGameFilterInput?]? = nil, or: [ModelSubscriptionGameFilterInput?]? = nil, owner: ModelStringInput? = nil) {
    graphQLMap = ["id": id, "gameName": gameName, "hostUserID": hostUserId, "playerIDs": playerIDs, "rounds": rounds, "customRules": customRules, "finalScores": finalScores, "gameStatus": gameStatus, "winCondition": winCondition, "maxScore": maxScore, "maxRounds": maxRounds, "createdAt": createdAt, "updatedAt": updatedAt, "and": and, "or": or, "owner": owner]
  }

  public var id: ModelSubscriptionIDInput? {
    get {
      return graphQLMap["id"] as! ModelSubscriptionIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var gameName: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["gameName"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gameName")
    }
  }

  public var hostUserId: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["hostUserID"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "hostUserID")
    }
  }

  public var playerIDs: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["playerIDs"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "playerIDs")
    }
  }

  public var rounds: ModelSubscriptionIntInput? {
    get {
      return graphQLMap["rounds"] as! ModelSubscriptionIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "rounds")
    }
  }

  public var customRules: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["customRules"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "customRules")
    }
  }

  public var finalScores: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["finalScores"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "finalScores")
    }
  }

  public var gameStatus: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["gameStatus"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gameStatus")
    }
  }

  public var winCondition: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["winCondition"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "winCondition")
    }
  }

  public var maxScore: ModelSubscriptionIntInput? {
    get {
      return graphQLMap["maxScore"] as! ModelSubscriptionIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "maxScore")
    }
  }

  public var maxRounds: ModelSubscriptionIntInput? {
    get {
      return graphQLMap["maxRounds"] as! ModelSubscriptionIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "maxRounds")
    }
  }

  public var createdAt: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var and: [ModelSubscriptionGameFilterInput?]? {
    get {
      return graphQLMap["and"] as! [ModelSubscriptionGameFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelSubscriptionGameFilterInput?]? {
    get {
      return graphQLMap["or"] as! [ModelSubscriptionGameFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var owner: ModelStringInput? {
    get {
      return graphQLMap["owner"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }
}

public struct ModelSubscriptionIDInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(ne: GraphQLID? = nil, eq: GraphQLID? = nil, le: GraphQLID? = nil, lt: GraphQLID? = nil, ge: GraphQLID? = nil, gt: GraphQLID? = nil, contains: GraphQLID? = nil, notContains: GraphQLID? = nil, between: [GraphQLID?]? = nil, beginsWith: GraphQLID? = nil, `in`: [GraphQLID?]? = nil, notIn: [GraphQLID?]? = nil) {
    graphQLMap = ["ne": ne, "eq": eq, "le": le, "lt": lt, "ge": ge, "gt": gt, "contains": contains, "notContains": notContains, "between": between, "beginsWith": beginsWith, "in": `in`, "notIn": notIn]
  }

  public var ne: GraphQLID? {
    get {
      return graphQLMap["ne"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }

  public var eq: GraphQLID? {
    get {
      return graphQLMap["eq"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var le: GraphQLID? {
    get {
      return graphQLMap["le"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "le")
    }
  }

  public var lt: GraphQLID? {
    get {
      return graphQLMap["lt"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lt")
    }
  }

  public var ge: GraphQLID? {
    get {
      return graphQLMap["ge"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ge")
    }
  }

  public var gt: GraphQLID? {
    get {
      return graphQLMap["gt"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gt")
    }
  }

  public var contains: GraphQLID? {
    get {
      return graphQLMap["contains"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "contains")
    }
  }

  public var notContains: GraphQLID? {
    get {
      return graphQLMap["notContains"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "notContains")
    }
  }

  public var between: [GraphQLID?]? {
    get {
      return graphQLMap["between"] as! [GraphQLID?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "between")
    }
  }

  public var beginsWith: GraphQLID? {
    get {
      return graphQLMap["beginsWith"] as! GraphQLID?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "beginsWith")
    }
  }

  public var `in`: [GraphQLID?]? {
    get {
      return graphQLMap["in"] as! [GraphQLID?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "in")
    }
  }

  public var notIn: [GraphQLID?]? {
    get {
      return graphQLMap["notIn"] as! [GraphQLID?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "notIn")
    }
  }
}

public struct ModelSubscriptionStringInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(ne: String? = nil, eq: String? = nil, le: String? = nil, lt: String? = nil, ge: String? = nil, gt: String? = nil, contains: String? = nil, notContains: String? = nil, between: [String?]? = nil, beginsWith: String? = nil, `in`: [String?]? = nil, notIn: [String?]? = nil) {
    graphQLMap = ["ne": ne, "eq": eq, "le": le, "lt": lt, "ge": ge, "gt": gt, "contains": contains, "notContains": notContains, "between": between, "beginsWith": beginsWith, "in": `in`, "notIn": notIn]
  }

  public var ne: String? {
    get {
      return graphQLMap["ne"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }

  public var eq: String? {
    get {
      return graphQLMap["eq"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var le: String? {
    get {
      return graphQLMap["le"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "le")
    }
  }

  public var lt: String? {
    get {
      return graphQLMap["lt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lt")
    }
  }

  public var ge: String? {
    get {
      return graphQLMap["ge"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ge")
    }
  }

  public var gt: String? {
    get {
      return graphQLMap["gt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gt")
    }
  }

  public var contains: String? {
    get {
      return graphQLMap["contains"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "contains")
    }
  }

  public var notContains: String? {
    get {
      return graphQLMap["notContains"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "notContains")
    }
  }

  public var between: [String?]? {
    get {
      return graphQLMap["between"] as! [String?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "between")
    }
  }

  public var beginsWith: String? {
    get {
      return graphQLMap["beginsWith"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "beginsWith")
    }
  }

  public var `in`: [String?]? {
    get {
      return graphQLMap["in"] as! [String?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "in")
    }
  }

  public var notIn: [String?]? {
    get {
      return graphQLMap["notIn"] as! [String?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "notIn")
    }
  }
}

public struct ModelSubscriptionIntInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(ne: Int? = nil, eq: Int? = nil, le: Int? = nil, lt: Int? = nil, ge: Int? = nil, gt: Int? = nil, between: [Int?]? = nil, `in`: [Int?]? = nil, notIn: [Int?]? = nil) {
    graphQLMap = ["ne": ne, "eq": eq, "le": le, "lt": lt, "ge": ge, "gt": gt, "between": between, "in": `in`, "notIn": notIn]
  }

  public var ne: Int? {
    get {
      return graphQLMap["ne"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }

  public var eq: Int? {
    get {
      return graphQLMap["eq"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var le: Int? {
    get {
      return graphQLMap["le"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "le")
    }
  }

  public var lt: Int? {
    get {
      return graphQLMap["lt"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lt")
    }
  }

  public var ge: Int? {
    get {
      return graphQLMap["ge"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ge")
    }
  }

  public var gt: Int? {
    get {
      return graphQLMap["gt"] as! Int?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gt")
    }
  }

  public var between: [Int?]? {
    get {
      return graphQLMap["between"] as! [Int?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "between")
    }
  }

  public var `in`: [Int?]? {
    get {
      return graphQLMap["in"] as! [Int?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "in")
    }
  }

  public var notIn: [Int?]? {
    get {
      return graphQLMap["notIn"] as! [Int?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "notIn")
    }
  }
}

public struct ModelSubscriptionScoreFilterInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: ModelSubscriptionIDInput? = nil, gameId: ModelSubscriptionStringInput? = nil, playerId: ModelSubscriptionStringInput? = nil, roundNumber: ModelSubscriptionIntInput? = nil, score: ModelSubscriptionIntInput? = nil, createdAt: ModelSubscriptionStringInput? = nil, updatedAt: ModelSubscriptionStringInput? = nil, and: [ModelSubscriptionScoreFilterInput?]? = nil, or: [ModelSubscriptionScoreFilterInput?]? = nil, owner: ModelStringInput? = nil) {
    graphQLMap = ["id": id, "gameID": gameId, "playerID": playerId, "roundNumber": roundNumber, "score": score, "createdAt": createdAt, "updatedAt": updatedAt, "and": and, "or": or, "owner": owner]
  }

  public var id: ModelSubscriptionIDInput? {
    get {
      return graphQLMap["id"] as! ModelSubscriptionIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var gameId: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["gameID"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gameID")
    }
  }

  public var playerId: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["playerID"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "playerID")
    }
  }

  public var roundNumber: ModelSubscriptionIntInput? {
    get {
      return graphQLMap["roundNumber"] as! ModelSubscriptionIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "roundNumber")
    }
  }

  public var score: ModelSubscriptionIntInput? {
    get {
      return graphQLMap["score"] as! ModelSubscriptionIntInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "score")
    }
  }

  public var createdAt: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var and: [ModelSubscriptionScoreFilterInput?]? {
    get {
      return graphQLMap["and"] as! [ModelSubscriptionScoreFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelSubscriptionScoreFilterInput?]? {
    get {
      return graphQLMap["or"] as! [ModelSubscriptionScoreFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var owner: ModelStringInput? {
    get {
      return graphQLMap["owner"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }
}

public struct ModelSubscriptionUserFilterInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(id: ModelSubscriptionIDInput? = nil, username: ModelSubscriptionStringInput? = nil, email: ModelSubscriptionStringInput? = nil, createdAt: ModelSubscriptionStringInput? = nil, updatedAt: ModelSubscriptionStringInput? = nil, and: [ModelSubscriptionUserFilterInput?]? = nil, or: [ModelSubscriptionUserFilterInput?]? = nil, owner: ModelStringInput? = nil) {
    graphQLMap = ["id": id, "username": username, "email": email, "createdAt": createdAt, "updatedAt": updatedAt, "and": and, "or": or, "owner": owner]
  }

  public var id: ModelSubscriptionIDInput? {
    get {
      return graphQLMap["id"] as! ModelSubscriptionIDInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "id")
    }
  }

  public var username: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["username"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "username")
    }
  }

  public var email: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["email"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "email")
    }
  }

  public var createdAt: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["createdAt"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "createdAt")
    }
  }

  public var updatedAt: ModelSubscriptionStringInput? {
    get {
      return graphQLMap["updatedAt"] as! ModelSubscriptionStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "updatedAt")
    }
  }

  public var and: [ModelSubscriptionUserFilterInput?]? {
    get {
      return graphQLMap["and"] as! [ModelSubscriptionUserFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "and")
    }
  }

  public var or: [ModelSubscriptionUserFilterInput?]? {
    get {
      return graphQLMap["or"] as! [ModelSubscriptionUserFilterInput?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "or")
    }
  }

  public var owner: ModelStringInput? {
    get {
      return graphQLMap["owner"] as! ModelStringInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "owner")
    }
  }
}

public final class CreateGameMutation: GraphQLMutation {
  public static let operationString =
    "mutation CreateGame($input: CreateGameInput!, $condition: ModelGameConditionInput) {\n  createGame(input: $input, condition: $condition) {\n    __typename\n    id\n    gameName\n    hostUserID\n    playerIDs\n    rounds\n    customRules\n    finalScores\n    gameStatus\n    winCondition\n    maxScore\n    maxRounds\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var input: CreateGameInput
  public var condition: ModelGameConditionInput?

  public init(input: CreateGameInput, condition: ModelGameConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("createGame", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(CreateGame.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(createGame: CreateGame? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "createGame": createGame.flatMap { $0.snapshot }])
    }

    public var createGame: CreateGame? {
      get {
        return (snapshot["createGame"] as? Snapshot).flatMap { CreateGame(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "createGame")
      }
    }

    public struct CreateGame: GraphQLSelectionSet {
      public static let possibleTypes = ["Game"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("gameName", type: .scalar(String.self)),
        GraphQLField("hostUserID", type: .nonNull(.scalar(String.self))),
        GraphQLField("playerIDs", type: .nonNull(.list(.nonNull(.scalar(String.self))))),
        GraphQLField("rounds", type: .nonNull(.scalar(Int.self))),
        GraphQLField("customRules", type: .scalar(String.self)),
        GraphQLField("finalScores", type: .nonNull(.list(.nonNull(.scalar(String.self))))),
        GraphQLField("gameStatus", type: .nonNull(.scalar(GameStatus.self))),
        GraphQLField("winCondition", type: .scalar(WinCondition.self)),
        GraphQLField("maxScore", type: .scalar(Int.self)),
        GraphQLField("maxRounds", type: .scalar(Int.self)),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, gameName: String? = nil, hostUserId: String, playerIDs: [String], rounds: Int, customRules: String? = nil, finalScores: [String], gameStatus: GameStatus, winCondition: WinCondition? = nil, maxScore: Int? = nil, maxRounds: Int? = nil, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "Game", "id": id, "gameName": gameName, "hostUserID": hostUserId, "playerIDs": playerIDs, "rounds": rounds, "customRules": customRules, "finalScores": finalScores, "gameStatus": gameStatus, "winCondition": winCondition, "maxScore": maxScore, "maxRounds": maxRounds, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var gameName: String? {
        get {
          return snapshot["gameName"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "gameName")
        }
      }

      public var hostUserId: String {
        get {
          return snapshot["hostUserID"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "hostUserID")
        }
      }

      public var playerIDs: [String] {
        get {
          return snapshot["playerIDs"]! as! [String]
        }
        set {
          snapshot.updateValue(newValue, forKey: "playerIDs")
        }
      }

      public var rounds: Int {
        get {
          return snapshot["rounds"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "rounds")
        }
      }

      public var customRules: String? {
        get {
          return snapshot["customRules"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "customRules")
        }
      }

      public var finalScores: [String] {
        get {
          return snapshot["finalScores"]! as! [String]
        }
        set {
          snapshot.updateValue(newValue, forKey: "finalScores")
        }
      }

      public var gameStatus: GameStatus {
        get {
          return snapshot["gameStatus"]! as! GameStatus
        }
        set {
          snapshot.updateValue(newValue, forKey: "gameStatus")
        }
      }

      public var winCondition: WinCondition? {
        get {
          return snapshot["winCondition"] as? WinCondition
        }
        set {
          snapshot.updateValue(newValue, forKey: "winCondition")
        }
      }

      public var maxScore: Int? {
        get {
          return snapshot["maxScore"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "maxScore")
        }
      }

      public var maxRounds: Int? {
        get {
          return snapshot["maxRounds"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "maxRounds")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }
    }
  }
}

public final class UpdateGameMutation: GraphQLMutation {
  public static let operationString =
    "mutation UpdateGame($input: UpdateGameInput!, $condition: ModelGameConditionInput) {\n  updateGame(input: $input, condition: $condition) {\n    __typename\n    id\n    gameName\n    hostUserID\n    playerIDs\n    rounds\n    customRules\n    finalScores\n    gameStatus\n    winCondition\n    maxScore\n    maxRounds\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var input: UpdateGameInput
  public var condition: ModelGameConditionInput?

  public init(input: UpdateGameInput, condition: ModelGameConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("updateGame", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(UpdateGame.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(updateGame: UpdateGame? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "updateGame": updateGame.flatMap { $0.snapshot }])
    }

    public var updateGame: UpdateGame? {
      get {
        return (snapshot["updateGame"] as? Snapshot).flatMap { UpdateGame(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "updateGame")
      }
    }

    public struct UpdateGame: GraphQLSelectionSet {
      public static let possibleTypes = ["Game"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("gameName", type: .scalar(String.self)),
        GraphQLField("hostUserID", type: .nonNull(.scalar(String.self))),
        GraphQLField("playerIDs", type: .nonNull(.list(.nonNull(.scalar(String.self))))),
        GraphQLField("rounds", type: .nonNull(.scalar(Int.self))),
        GraphQLField("customRules", type: .scalar(String.self)),
        GraphQLField("finalScores", type: .nonNull(.list(.nonNull(.scalar(String.self))))),
        GraphQLField("gameStatus", type: .nonNull(.scalar(GameStatus.self))),
        GraphQLField("winCondition", type: .scalar(WinCondition.self)),
        GraphQLField("maxScore", type: .scalar(Int.self)),
        GraphQLField("maxRounds", type: .scalar(Int.self)),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, gameName: String? = nil, hostUserId: String, playerIDs: [String], rounds: Int, customRules: String? = nil, finalScores: [String], gameStatus: GameStatus, winCondition: WinCondition? = nil, maxScore: Int? = nil, maxRounds: Int? = nil, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "Game", "id": id, "gameName": gameName, "hostUserID": hostUserId, "playerIDs": playerIDs, "rounds": rounds, "customRules": customRules, "finalScores": finalScores, "gameStatus": gameStatus, "winCondition": winCondition, "maxScore": maxScore, "maxRounds": maxRounds, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var gameName: String? {
        get {
          return snapshot["gameName"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "gameName")
        }
      }

      public var hostUserId: String {
        get {
          return snapshot["hostUserID"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "hostUserID")
        }
      }

      public var playerIDs: [String] {
        get {
          return snapshot["playerIDs"]! as! [String]
        }
        set {
          snapshot.updateValue(newValue, forKey: "playerIDs")
        }
      }

      public var rounds: Int {
        get {
          return snapshot["rounds"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "rounds")
        }
      }

      public var customRules: String? {
        get {
          return snapshot["customRules"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "customRules")
        }
      }

      public var finalScores: [String] {
        get {
          return snapshot["finalScores"]! as! [String]
        }
        set {
          snapshot.updateValue(newValue, forKey: "finalScores")
        }
      }

      public var gameStatus: GameStatus {
        get {
          return snapshot["gameStatus"]! as! GameStatus
        }
        set {
          snapshot.updateValue(newValue, forKey: "gameStatus")
        }
      }

      public var winCondition: WinCondition? {
        get {
          return snapshot["winCondition"] as? WinCondition
        }
        set {
          snapshot.updateValue(newValue, forKey: "winCondition")
        }
      }

      public var maxScore: Int? {
        get {
          return snapshot["maxScore"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "maxScore")
        }
      }

      public var maxRounds: Int? {
        get {
          return snapshot["maxRounds"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "maxRounds")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }
    }
  }
}

public final class DeleteGameMutation: GraphQLMutation {
  public static let operationString =
    "mutation DeleteGame($input: DeleteGameInput!, $condition: ModelGameConditionInput) {\n  deleteGame(input: $input, condition: $condition) {\n    __typename\n    id\n    gameName\n    hostUserID\n    playerIDs\n    rounds\n    customRules\n    finalScores\n    gameStatus\n    winCondition\n    maxScore\n    maxRounds\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var input: DeleteGameInput
  public var condition: ModelGameConditionInput?

  public init(input: DeleteGameInput, condition: ModelGameConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("deleteGame", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(DeleteGame.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(deleteGame: DeleteGame? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "deleteGame": deleteGame.flatMap { $0.snapshot }])
    }

    public var deleteGame: DeleteGame? {
      get {
        return (snapshot["deleteGame"] as? Snapshot).flatMap { DeleteGame(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "deleteGame")
      }
    }

    public struct DeleteGame: GraphQLSelectionSet {
      public static let possibleTypes = ["Game"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("gameName", type: .scalar(String.self)),
        GraphQLField("hostUserID", type: .nonNull(.scalar(String.self))),
        GraphQLField("playerIDs", type: .nonNull(.list(.nonNull(.scalar(String.self))))),
        GraphQLField("rounds", type: .nonNull(.scalar(Int.self))),
        GraphQLField("customRules", type: .scalar(String.self)),
        GraphQLField("finalScores", type: .nonNull(.list(.nonNull(.scalar(String.self))))),
        GraphQLField("gameStatus", type: .nonNull(.scalar(GameStatus.self))),
        GraphQLField("winCondition", type: .scalar(WinCondition.self)),
        GraphQLField("maxScore", type: .scalar(Int.self)),
        GraphQLField("maxRounds", type: .scalar(Int.self)),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, gameName: String? = nil, hostUserId: String, playerIDs: [String], rounds: Int, customRules: String? = nil, finalScores: [String], gameStatus: GameStatus, winCondition: WinCondition? = nil, maxScore: Int? = nil, maxRounds: Int? = nil, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "Game", "id": id, "gameName": gameName, "hostUserID": hostUserId, "playerIDs": playerIDs, "rounds": rounds, "customRules": customRules, "finalScores": finalScores, "gameStatus": gameStatus, "winCondition": winCondition, "maxScore": maxScore, "maxRounds": maxRounds, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var gameName: String? {
        get {
          return snapshot["gameName"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "gameName")
        }
      }

      public var hostUserId: String {
        get {
          return snapshot["hostUserID"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "hostUserID")
        }
      }

      public var playerIDs: [String] {
        get {
          return snapshot["playerIDs"]! as! [String]
        }
        set {
          snapshot.updateValue(newValue, forKey: "playerIDs")
        }
      }

      public var rounds: Int {
        get {
          return snapshot["rounds"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "rounds")
        }
      }

      public var customRules: String? {
        get {
          return snapshot["customRules"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "customRules")
        }
      }

      public var finalScores: [String] {
        get {
          return snapshot["finalScores"]! as! [String]
        }
        set {
          snapshot.updateValue(newValue, forKey: "finalScores")
        }
      }

      public var gameStatus: GameStatus {
        get {
          return snapshot["gameStatus"]! as! GameStatus
        }
        set {
          snapshot.updateValue(newValue, forKey: "gameStatus")
        }
      }

      public var winCondition: WinCondition? {
        get {
          return snapshot["winCondition"] as? WinCondition
        }
        set {
          snapshot.updateValue(newValue, forKey: "winCondition")
        }
      }

      public var maxScore: Int? {
        get {
          return snapshot["maxScore"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "maxScore")
        }
      }

      public var maxRounds: Int? {
        get {
          return snapshot["maxRounds"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "maxRounds")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }
    }
  }
}

public final class CreateScoreMutation: GraphQLMutation {
  public static let operationString =
    "mutation CreateScore($input: CreateScoreInput!, $condition: ModelScoreConditionInput) {\n  createScore(input: $input, condition: $condition) {\n    __typename\n    id\n    gameID\n    playerID\n    roundNumber\n    score\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var input: CreateScoreInput
  public var condition: ModelScoreConditionInput?

  public init(input: CreateScoreInput, condition: ModelScoreConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("createScore", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(CreateScore.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(createScore: CreateScore? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "createScore": createScore.flatMap { $0.snapshot }])
    }

    public var createScore: CreateScore? {
      get {
        return (snapshot["createScore"] as? Snapshot).flatMap { CreateScore(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "createScore")
      }
    }

    public struct CreateScore: GraphQLSelectionSet {
      public static let possibleTypes = ["Score"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("gameID", type: .nonNull(.scalar(String.self))),
        GraphQLField("playerID", type: .nonNull(.scalar(String.self))),
        GraphQLField("roundNumber", type: .nonNull(.scalar(Int.self))),
        GraphQLField("score", type: .nonNull(.scalar(Int.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, gameId: String, playerId: String, roundNumber: Int, score: Int, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "Score", "id": id, "gameID": gameId, "playerID": playerId, "roundNumber": roundNumber, "score": score, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var gameId: String {
        get {
          return snapshot["gameID"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "gameID")
        }
      }

      public var playerId: String {
        get {
          return snapshot["playerID"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "playerID")
        }
      }

      public var roundNumber: Int {
        get {
          return snapshot["roundNumber"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "roundNumber")
        }
      }

      public var score: Int {
        get {
          return snapshot["score"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "score")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }
    }
  }
}

public final class UpdateScoreMutation: GraphQLMutation {
  public static let operationString =
    "mutation UpdateScore($input: UpdateScoreInput!, $condition: ModelScoreConditionInput) {\n  updateScore(input: $input, condition: $condition) {\n    __typename\n    id\n    gameID\n    playerID\n    roundNumber\n    score\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var input: UpdateScoreInput
  public var condition: ModelScoreConditionInput?

  public init(input: UpdateScoreInput, condition: ModelScoreConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("updateScore", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(UpdateScore.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(updateScore: UpdateScore? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "updateScore": updateScore.flatMap { $0.snapshot }])
    }

    public var updateScore: UpdateScore? {
      get {
        return (snapshot["updateScore"] as? Snapshot).flatMap { UpdateScore(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "updateScore")
      }
    }

    public struct UpdateScore: GraphQLSelectionSet {
      public static let possibleTypes = ["Score"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("gameID", type: .nonNull(.scalar(String.self))),
        GraphQLField("playerID", type: .nonNull(.scalar(String.self))),
        GraphQLField("roundNumber", type: .nonNull(.scalar(Int.self))),
        GraphQLField("score", type: .nonNull(.scalar(Int.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, gameId: String, playerId: String, roundNumber: Int, score: Int, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "Score", "id": id, "gameID": gameId, "playerID": playerId, "roundNumber": roundNumber, "score": score, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var gameId: String {
        get {
          return snapshot["gameID"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "gameID")
        }
      }

      public var playerId: String {
        get {
          return snapshot["playerID"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "playerID")
        }
      }

      public var roundNumber: Int {
        get {
          return snapshot["roundNumber"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "roundNumber")
        }
      }

      public var score: Int {
        get {
          return snapshot["score"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "score")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }
    }
  }
}

public final class DeleteScoreMutation: GraphQLMutation {
  public static let operationString =
    "mutation DeleteScore($input: DeleteScoreInput!, $condition: ModelScoreConditionInput) {\n  deleteScore(input: $input, condition: $condition) {\n    __typename\n    id\n    gameID\n    playerID\n    roundNumber\n    score\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var input: DeleteScoreInput
  public var condition: ModelScoreConditionInput?

  public init(input: DeleteScoreInput, condition: ModelScoreConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("deleteScore", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(DeleteScore.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(deleteScore: DeleteScore? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "deleteScore": deleteScore.flatMap { $0.snapshot }])
    }

    public var deleteScore: DeleteScore? {
      get {
        return (snapshot["deleteScore"] as? Snapshot).flatMap { DeleteScore(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "deleteScore")
      }
    }

    public struct DeleteScore: GraphQLSelectionSet {
      public static let possibleTypes = ["Score"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("gameID", type: .nonNull(.scalar(String.self))),
        GraphQLField("playerID", type: .nonNull(.scalar(String.self))),
        GraphQLField("roundNumber", type: .nonNull(.scalar(Int.self))),
        GraphQLField("score", type: .nonNull(.scalar(Int.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, gameId: String, playerId: String, roundNumber: Int, score: Int, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "Score", "id": id, "gameID": gameId, "playerID": playerId, "roundNumber": roundNumber, "score": score, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var gameId: String {
        get {
          return snapshot["gameID"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "gameID")
        }
      }

      public var playerId: String {
        get {
          return snapshot["playerID"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "playerID")
        }
      }

      public var roundNumber: Int {
        get {
          return snapshot["roundNumber"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "roundNumber")
        }
      }

      public var score: Int {
        get {
          return snapshot["score"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "score")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }
    }
  }
}

public final class CreateUserMutation: GraphQLMutation {
  public static let operationString =
    "mutation CreateUser($input: CreateUserInput!, $condition: ModelUserConditionInput) {\n  createUser(input: $input, condition: $condition) {\n    __typename\n    id\n    username\n    email\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var input: CreateUserInput
  public var condition: ModelUserConditionInput?

  public init(input: CreateUserInput, condition: ModelUserConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("createUser", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(CreateUser.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(createUser: CreateUser? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "createUser": createUser.flatMap { $0.snapshot }])
    }

    public var createUser: CreateUser? {
      get {
        return (snapshot["createUser"] as? Snapshot).flatMap { CreateUser(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "createUser")
      }
    }

    public struct CreateUser: GraphQLSelectionSet {
      public static let possibleTypes = ["User"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("username", type: .nonNull(.scalar(String.self))),
        GraphQLField("email", type: .nonNull(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, username: String, email: String, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "User", "id": id, "username": username, "email": email, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var username: String {
        get {
          return snapshot["username"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "username")
        }
      }

      public var email: String {
        get {
          return snapshot["email"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "email")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }
    }
  }
}

public final class UpdateUserMutation: GraphQLMutation {
  public static let operationString =
    "mutation UpdateUser($input: UpdateUserInput!, $condition: ModelUserConditionInput) {\n  updateUser(input: $input, condition: $condition) {\n    __typename\n    id\n    username\n    email\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var input: UpdateUserInput
  public var condition: ModelUserConditionInput?

  public init(input: UpdateUserInput, condition: ModelUserConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("updateUser", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(UpdateUser.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(updateUser: UpdateUser? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "updateUser": updateUser.flatMap { $0.snapshot }])
    }

    public var updateUser: UpdateUser? {
      get {
        return (snapshot["updateUser"] as? Snapshot).flatMap { UpdateUser(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "updateUser")
      }
    }

    public struct UpdateUser: GraphQLSelectionSet {
      public static let possibleTypes = ["User"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("username", type: .nonNull(.scalar(String.self))),
        GraphQLField("email", type: .nonNull(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, username: String, email: String, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "User", "id": id, "username": username, "email": email, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var username: String {
        get {
          return snapshot["username"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "username")
        }
      }

      public var email: String {
        get {
          return snapshot["email"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "email")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }
    }
  }
}

public final class DeleteUserMutation: GraphQLMutation {
  public static let operationString =
    "mutation DeleteUser($input: DeleteUserInput!, $condition: ModelUserConditionInput) {\n  deleteUser(input: $input, condition: $condition) {\n    __typename\n    id\n    username\n    email\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var input: DeleteUserInput
  public var condition: ModelUserConditionInput?

  public init(input: DeleteUserInput, condition: ModelUserConditionInput? = nil) {
    self.input = input
    self.condition = condition
  }

  public var variables: GraphQLMap? {
    return ["input": input, "condition": condition]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("deleteUser", arguments: ["input": GraphQLVariable("input"), "condition": GraphQLVariable("condition")], type: .object(DeleteUser.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(deleteUser: DeleteUser? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "deleteUser": deleteUser.flatMap { $0.snapshot }])
    }

    public var deleteUser: DeleteUser? {
      get {
        return (snapshot["deleteUser"] as? Snapshot).flatMap { DeleteUser(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "deleteUser")
      }
    }

    public struct DeleteUser: GraphQLSelectionSet {
      public static let possibleTypes = ["User"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("username", type: .nonNull(.scalar(String.self))),
        GraphQLField("email", type: .nonNull(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, username: String, email: String, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "User", "id": id, "username": username, "email": email, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var username: String {
        get {
          return snapshot["username"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "username")
        }
      }

      public var email: String {
        get {
          return snapshot["email"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "email")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }
    }
  }
}

public final class GetGameQuery: GraphQLQuery {
  public static let operationString =
    "query GetGame($id: ID!) {\n  getGame(id: $id) {\n    __typename\n    id\n    gameName\n    hostUserID\n    playerIDs\n    rounds\n    customRules\n    finalScores\n    gameStatus\n    winCondition\n    maxScore\n    maxRounds\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var id: GraphQLID

  public init(id: GraphQLID) {
    self.id = id
  }

  public var variables: GraphQLMap? {
    return ["id": id]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("getGame", arguments: ["id": GraphQLVariable("id")], type: .object(GetGame.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(getGame: GetGame? = nil) {
      self.init(snapshot: ["__typename": "Query", "getGame": getGame.flatMap { $0.snapshot }])
    }

    public var getGame: GetGame? {
      get {
        return (snapshot["getGame"] as? Snapshot).flatMap { GetGame(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "getGame")
      }
    }

    public struct GetGame: GraphQLSelectionSet {
      public static let possibleTypes = ["Game"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("gameName", type: .scalar(String.self)),
        GraphQLField("hostUserID", type: .nonNull(.scalar(String.self))),
        GraphQLField("playerIDs", type: .nonNull(.list(.nonNull(.scalar(String.self))))),
        GraphQLField("rounds", type: .nonNull(.scalar(Int.self))),
        GraphQLField("customRules", type: .scalar(String.self)),
        GraphQLField("finalScores", type: .nonNull(.list(.nonNull(.scalar(String.self))))),
        GraphQLField("gameStatus", type: .nonNull(.scalar(GameStatus.self))),
        GraphQLField("winCondition", type: .scalar(WinCondition.self)),
        GraphQLField("maxScore", type: .scalar(Int.self)),
        GraphQLField("maxRounds", type: .scalar(Int.self)),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, gameName: String? = nil, hostUserId: String, playerIDs: [String], rounds: Int, customRules: String? = nil, finalScores: [String], gameStatus: GameStatus, winCondition: WinCondition? = nil, maxScore: Int? = nil, maxRounds: Int? = nil, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "Game", "id": id, "gameName": gameName, "hostUserID": hostUserId, "playerIDs": playerIDs, "rounds": rounds, "customRules": customRules, "finalScores": finalScores, "gameStatus": gameStatus, "winCondition": winCondition, "maxScore": maxScore, "maxRounds": maxRounds, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var gameName: String? {
        get {
          return snapshot["gameName"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "gameName")
        }
      }

      public var hostUserId: String {
        get {
          return snapshot["hostUserID"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "hostUserID")
        }
      }

      public var playerIDs: [String] {
        get {
          return snapshot["playerIDs"]! as! [String]
        }
        set {
          snapshot.updateValue(newValue, forKey: "playerIDs")
        }
      }

      public var rounds: Int {
        get {
          return snapshot["rounds"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "rounds")
        }
      }

      public var customRules: String? {
        get {
          return snapshot["customRules"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "customRules")
        }
      }

      public var finalScores: [String] {
        get {
          return snapshot["finalScores"]! as! [String]
        }
        set {
          snapshot.updateValue(newValue, forKey: "finalScores")
        }
      }

      public var gameStatus: GameStatus {
        get {
          return snapshot["gameStatus"]! as! GameStatus
        }
        set {
          snapshot.updateValue(newValue, forKey: "gameStatus")
        }
      }

      public var winCondition: WinCondition? {
        get {
          return snapshot["winCondition"] as? WinCondition
        }
        set {
          snapshot.updateValue(newValue, forKey: "winCondition")
        }
      }

      public var maxScore: Int? {
        get {
          return snapshot["maxScore"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "maxScore")
        }
      }

      public var maxRounds: Int? {
        get {
          return snapshot["maxRounds"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "maxRounds")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }
    }
  }
}

public final class ListGamesQuery: GraphQLQuery {
  public static let operationString =
    "query ListGames($filter: ModelGameFilterInput, $limit: Int, $nextToken: String) {\n  listGames(filter: $filter, limit: $limit, nextToken: $nextToken) {\n    __typename\n    items {\n      __typename\n      id\n      gameName\n      hostUserID\n      playerIDs\n      rounds\n      customRules\n      finalScores\n      gameStatus\n      winCondition\n      maxScore\n      maxRounds\n      createdAt\n      updatedAt\n      owner\n    }\n    nextToken\n  }\n}"

  public var filter: ModelGameFilterInput?
  public var limit: Int?
  public var nextToken: String?

  public init(filter: ModelGameFilterInput? = nil, limit: Int? = nil, nextToken: String? = nil) {
    self.filter = filter
    self.limit = limit
    self.nextToken = nextToken
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "limit": limit, "nextToken": nextToken]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("listGames", arguments: ["filter": GraphQLVariable("filter"), "limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken")], type: .object(ListGame.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(listGames: ListGame? = nil) {
      self.init(snapshot: ["__typename": "Query", "listGames": listGames.flatMap { $0.snapshot }])
    }

    public var listGames: ListGame? {
      get {
        return (snapshot["listGames"] as? Snapshot).flatMap { ListGame(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "listGames")
      }
    }

    public struct ListGame: GraphQLSelectionSet {
      public static let possibleTypes = ["ModelGameConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .nonNull(.list(.object(Item.selections)))),
        GraphQLField("nextToken", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(items: [Item?], nextToken: String? = nil) {
        self.init(snapshot: ["__typename": "ModelGameConnection", "items": items.map { $0.flatMap { $0.snapshot } }, "nextToken": nextToken])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var items: [Item?] {
        get {
          return (snapshot["items"] as! [Snapshot?]).map { $0.flatMap { Item(snapshot: $0) } }
        }
        set {
          snapshot.updateValue(newValue.map { $0.flatMap { $0.snapshot } }, forKey: "items")
        }
      }

      public var nextToken: String? {
        get {
          return snapshot["nextToken"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "nextToken")
        }
      }

      public struct Item: GraphQLSelectionSet {
        public static let possibleTypes = ["Game"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("gameName", type: .scalar(String.self)),
          GraphQLField("hostUserID", type: .nonNull(.scalar(String.self))),
          GraphQLField("playerIDs", type: .nonNull(.list(.nonNull(.scalar(String.self))))),
          GraphQLField("rounds", type: .nonNull(.scalar(Int.self))),
          GraphQLField("customRules", type: .scalar(String.self)),
          GraphQLField("finalScores", type: .nonNull(.list(.nonNull(.scalar(String.self))))),
          GraphQLField("gameStatus", type: .nonNull(.scalar(GameStatus.self))),
          GraphQLField("winCondition", type: .scalar(WinCondition.self)),
          GraphQLField("maxScore", type: .scalar(Int.self)),
          GraphQLField("maxRounds", type: .scalar(Int.self)),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("owner", type: .scalar(String.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, gameName: String? = nil, hostUserId: String, playerIDs: [String], rounds: Int, customRules: String? = nil, finalScores: [String], gameStatus: GameStatus, winCondition: WinCondition? = nil, maxScore: Int? = nil, maxRounds: Int? = nil, createdAt: String, updatedAt: String, owner: String? = nil) {
          self.init(snapshot: ["__typename": "Game", "id": id, "gameName": gameName, "hostUserID": hostUserId, "playerIDs": playerIDs, "rounds": rounds, "customRules": customRules, "finalScores": finalScores, "gameStatus": gameStatus, "winCondition": winCondition, "maxScore": maxScore, "maxRounds": maxRounds, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var gameName: String? {
          get {
            return snapshot["gameName"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "gameName")
          }
        }

        public var hostUserId: String {
          get {
            return snapshot["hostUserID"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "hostUserID")
          }
        }

        public var playerIDs: [String] {
          get {
            return snapshot["playerIDs"]! as! [String]
          }
          set {
            snapshot.updateValue(newValue, forKey: "playerIDs")
          }
        }

        public var rounds: Int {
          get {
            return snapshot["rounds"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "rounds")
          }
        }

        public var customRules: String? {
          get {
            return snapshot["customRules"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "customRules")
          }
        }

        public var finalScores: [String] {
          get {
            return snapshot["finalScores"]! as! [String]
          }
          set {
            snapshot.updateValue(newValue, forKey: "finalScores")
          }
        }

        public var gameStatus: GameStatus {
          get {
            return snapshot["gameStatus"]! as! GameStatus
          }
          set {
            snapshot.updateValue(newValue, forKey: "gameStatus")
          }
        }

        public var winCondition: WinCondition? {
          get {
            return snapshot["winCondition"] as? WinCondition
          }
          set {
            snapshot.updateValue(newValue, forKey: "winCondition")
          }
        }

        public var maxScore: Int? {
          get {
            return snapshot["maxScore"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "maxScore")
          }
        }

        public var maxRounds: Int? {
          get {
            return snapshot["maxRounds"] as? Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "maxRounds")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var owner: String? {
          get {
            return snapshot["owner"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "owner")
          }
        }
      }
    }
  }
}

public final class GetScoreQuery: GraphQLQuery {
  public static let operationString =
    "query GetScore($id: ID!) {\n  getScore(id: $id) {\n    __typename\n    id\n    gameID\n    playerID\n    roundNumber\n    score\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var id: GraphQLID

  public init(id: GraphQLID) {
    self.id = id
  }

  public var variables: GraphQLMap? {
    return ["id": id]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("getScore", arguments: ["id": GraphQLVariable("id")], type: .object(GetScore.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(getScore: GetScore? = nil) {
      self.init(snapshot: ["__typename": "Query", "getScore": getScore.flatMap { $0.snapshot }])
    }

    public var getScore: GetScore? {
      get {
        return (snapshot["getScore"] as? Snapshot).flatMap { GetScore(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "getScore")
      }
    }

    public struct GetScore: GraphQLSelectionSet {
      public static let possibleTypes = ["Score"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("gameID", type: .nonNull(.scalar(String.self))),
        GraphQLField("playerID", type: .nonNull(.scalar(String.self))),
        GraphQLField("roundNumber", type: .nonNull(.scalar(Int.self))),
        GraphQLField("score", type: .nonNull(.scalar(Int.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, gameId: String, playerId: String, roundNumber: Int, score: Int, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "Score", "id": id, "gameID": gameId, "playerID": playerId, "roundNumber": roundNumber, "score": score, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var gameId: String {
        get {
          return snapshot["gameID"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "gameID")
        }
      }

      public var playerId: String {
        get {
          return snapshot["playerID"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "playerID")
        }
      }

      public var roundNumber: Int {
        get {
          return snapshot["roundNumber"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "roundNumber")
        }
      }

      public var score: Int {
        get {
          return snapshot["score"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "score")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }
    }
  }
}

public final class ListScoresQuery: GraphQLQuery {
  public static let operationString =
    "query ListScores($filter: ModelScoreFilterInput, $limit: Int, $nextToken: String) {\n  listScores(filter: $filter, limit: $limit, nextToken: $nextToken) {\n    __typename\n    items {\n      __typename\n      id\n      gameID\n      playerID\n      roundNumber\n      score\n      createdAt\n      updatedAt\n      owner\n    }\n    nextToken\n  }\n}"

  public var filter: ModelScoreFilterInput?
  public var limit: Int?
  public var nextToken: String?

  public init(filter: ModelScoreFilterInput? = nil, limit: Int? = nil, nextToken: String? = nil) {
    self.filter = filter
    self.limit = limit
    self.nextToken = nextToken
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "limit": limit, "nextToken": nextToken]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("listScores", arguments: ["filter": GraphQLVariable("filter"), "limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken")], type: .object(ListScore.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(listScores: ListScore? = nil) {
      self.init(snapshot: ["__typename": "Query", "listScores": listScores.flatMap { $0.snapshot }])
    }

    public var listScores: ListScore? {
      get {
        return (snapshot["listScores"] as? Snapshot).flatMap { ListScore(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "listScores")
      }
    }

    public struct ListScore: GraphQLSelectionSet {
      public static let possibleTypes = ["ModelScoreConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .nonNull(.list(.object(Item.selections)))),
        GraphQLField("nextToken", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(items: [Item?], nextToken: String? = nil) {
        self.init(snapshot: ["__typename": "ModelScoreConnection", "items": items.map { $0.flatMap { $0.snapshot } }, "nextToken": nextToken])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var items: [Item?] {
        get {
          return (snapshot["items"] as! [Snapshot?]).map { $0.flatMap { Item(snapshot: $0) } }
        }
        set {
          snapshot.updateValue(newValue.map { $0.flatMap { $0.snapshot } }, forKey: "items")
        }
      }

      public var nextToken: String? {
        get {
          return snapshot["nextToken"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "nextToken")
        }
      }

      public struct Item: GraphQLSelectionSet {
        public static let possibleTypes = ["Score"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("gameID", type: .nonNull(.scalar(String.self))),
          GraphQLField("playerID", type: .nonNull(.scalar(String.self))),
          GraphQLField("roundNumber", type: .nonNull(.scalar(Int.self))),
          GraphQLField("score", type: .nonNull(.scalar(Int.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("owner", type: .scalar(String.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, gameId: String, playerId: String, roundNumber: Int, score: Int, createdAt: String, updatedAt: String, owner: String? = nil) {
          self.init(snapshot: ["__typename": "Score", "id": id, "gameID": gameId, "playerID": playerId, "roundNumber": roundNumber, "score": score, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var gameId: String {
          get {
            return snapshot["gameID"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "gameID")
          }
        }

        public var playerId: String {
          get {
            return snapshot["playerID"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "playerID")
          }
        }

        public var roundNumber: Int {
          get {
            return snapshot["roundNumber"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "roundNumber")
          }
        }

        public var score: Int {
          get {
            return snapshot["score"]! as! Int
          }
          set {
            snapshot.updateValue(newValue, forKey: "score")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var owner: String? {
          get {
            return snapshot["owner"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "owner")
          }
        }
      }
    }
  }
}

public final class GetUserQuery: GraphQLQuery {
  public static let operationString =
    "query GetUser($id: ID!) {\n  getUser(id: $id) {\n    __typename\n    id\n    username\n    email\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var id: GraphQLID

  public init(id: GraphQLID) {
    self.id = id
  }

  public var variables: GraphQLMap? {
    return ["id": id]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("getUser", arguments: ["id": GraphQLVariable("id")], type: .object(GetUser.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(getUser: GetUser? = nil) {
      self.init(snapshot: ["__typename": "Query", "getUser": getUser.flatMap { $0.snapshot }])
    }

    public var getUser: GetUser? {
      get {
        return (snapshot["getUser"] as? Snapshot).flatMap { GetUser(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "getUser")
      }
    }

    public struct GetUser: GraphQLSelectionSet {
      public static let possibleTypes = ["User"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("username", type: .nonNull(.scalar(String.self))),
        GraphQLField("email", type: .nonNull(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, username: String, email: String, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "User", "id": id, "username": username, "email": email, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var username: String {
        get {
          return snapshot["username"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "username")
        }
      }

      public var email: String {
        get {
          return snapshot["email"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "email")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }
    }
  }
}

public final class ListUsersQuery: GraphQLQuery {
  public static let operationString =
    "query ListUsers($filter: ModelUserFilterInput, $limit: Int, $nextToken: String) {\n  listUsers(filter: $filter, limit: $limit, nextToken: $nextToken) {\n    __typename\n    items {\n      __typename\n      id\n      username\n      email\n      createdAt\n      updatedAt\n      owner\n    }\n    nextToken\n  }\n}"

  public var filter: ModelUserFilterInput?
  public var limit: Int?
  public var nextToken: String?

  public init(filter: ModelUserFilterInput? = nil, limit: Int? = nil, nextToken: String? = nil) {
    self.filter = filter
    self.limit = limit
    self.nextToken = nextToken
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "limit": limit, "nextToken": nextToken]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("listUsers", arguments: ["filter": GraphQLVariable("filter"), "limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken")], type: .object(ListUser.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(listUsers: ListUser? = nil) {
      self.init(snapshot: ["__typename": "Query", "listUsers": listUsers.flatMap { $0.snapshot }])
    }

    public var listUsers: ListUser? {
      get {
        return (snapshot["listUsers"] as? Snapshot).flatMap { ListUser(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "listUsers")
      }
    }

    public struct ListUser: GraphQLSelectionSet {
      public static let possibleTypes = ["ModelUserConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .nonNull(.list(.object(Item.selections)))),
        GraphQLField("nextToken", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(items: [Item?], nextToken: String? = nil) {
        self.init(snapshot: ["__typename": "ModelUserConnection", "items": items.map { $0.flatMap { $0.snapshot } }, "nextToken": nextToken])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var items: [Item?] {
        get {
          return (snapshot["items"] as! [Snapshot?]).map { $0.flatMap { Item(snapshot: $0) } }
        }
        set {
          snapshot.updateValue(newValue.map { $0.flatMap { $0.snapshot } }, forKey: "items")
        }
      }

      public var nextToken: String? {
        get {
          return snapshot["nextToken"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "nextToken")
        }
      }

      public struct Item: GraphQLSelectionSet {
        public static let possibleTypes = ["User"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("email", type: .nonNull(.scalar(String.self))),
          GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
          GraphQLField("owner", type: .scalar(String.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(id: GraphQLID, username: String, email: String, createdAt: String, updatedAt: String, owner: String? = nil) {
          self.init(snapshot: ["__typename": "User", "id": id, "username": username, "email": email, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: GraphQLID {
          get {
            return snapshot["id"]! as! GraphQLID
          }
          set {
            snapshot.updateValue(newValue, forKey: "id")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var email: String {
          get {
            return snapshot["email"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "email")
          }
        }

        public var createdAt: String {
          get {
            return snapshot["createdAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "createdAt")
          }
        }

        public var updatedAt: String {
          get {
            return snapshot["updatedAt"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "updatedAt")
          }
        }

        public var owner: String? {
          get {
            return snapshot["owner"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "owner")
          }
        }
      }
    }
  }
}

public final class OnCreateGameSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnCreateGame($filter: ModelSubscriptionGameFilterInput, $owner: String) {\n  onCreateGame(filter: $filter, owner: $owner) {\n    __typename\n    id\n    gameName\n    hostUserID\n    playerIDs\n    rounds\n    customRules\n    finalScores\n    gameStatus\n    winCondition\n    maxScore\n    maxRounds\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var filter: ModelSubscriptionGameFilterInput?
  public var owner: String?

  public init(filter: ModelSubscriptionGameFilterInput? = nil, owner: String? = nil) {
    self.filter = filter
    self.owner = owner
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "owner": owner]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onCreateGame", arguments: ["filter": GraphQLVariable("filter"), "owner": GraphQLVariable("owner")], type: .object(OnCreateGame.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onCreateGame: OnCreateGame? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onCreateGame": onCreateGame.flatMap { $0.snapshot }])
    }

    public var onCreateGame: OnCreateGame? {
      get {
        return (snapshot["onCreateGame"] as? Snapshot).flatMap { OnCreateGame(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onCreateGame")
      }
    }

    public struct OnCreateGame: GraphQLSelectionSet {
      public static let possibleTypes = ["Game"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("gameName", type: .scalar(String.self)),
        GraphQLField("hostUserID", type: .nonNull(.scalar(String.self))),
        GraphQLField("playerIDs", type: .nonNull(.list(.nonNull(.scalar(String.self))))),
        GraphQLField("rounds", type: .nonNull(.scalar(Int.self))),
        GraphQLField("customRules", type: .scalar(String.self)),
        GraphQLField("finalScores", type: .nonNull(.list(.nonNull(.scalar(String.self))))),
        GraphQLField("gameStatus", type: .nonNull(.scalar(GameStatus.self))),
        GraphQLField("winCondition", type: .scalar(WinCondition.self)),
        GraphQLField("maxScore", type: .scalar(Int.self)),
        GraphQLField("maxRounds", type: .scalar(Int.self)),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, gameName: String? = nil, hostUserId: String, playerIDs: [String], rounds: Int, customRules: String? = nil, finalScores: [String], gameStatus: GameStatus, winCondition: WinCondition? = nil, maxScore: Int? = nil, maxRounds: Int? = nil, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "Game", "id": id, "gameName": gameName, "hostUserID": hostUserId, "playerIDs": playerIDs, "rounds": rounds, "customRules": customRules, "finalScores": finalScores, "gameStatus": gameStatus, "winCondition": winCondition, "maxScore": maxScore, "maxRounds": maxRounds, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var gameName: String? {
        get {
          return snapshot["gameName"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "gameName")
        }
      }

      public var hostUserId: String {
        get {
          return snapshot["hostUserID"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "hostUserID")
        }
      }

      public var playerIDs: [String] {
        get {
          return snapshot["playerIDs"]! as! [String]
        }
        set {
          snapshot.updateValue(newValue, forKey: "playerIDs")
        }
      }

      public var rounds: Int {
        get {
          return snapshot["rounds"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "rounds")
        }
      }

      public var customRules: String? {
        get {
          return snapshot["customRules"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "customRules")
        }
      }

      public var finalScores: [String] {
        get {
          return snapshot["finalScores"]! as! [String]
        }
        set {
          snapshot.updateValue(newValue, forKey: "finalScores")
        }
      }

      public var gameStatus: GameStatus {
        get {
          return snapshot["gameStatus"]! as! GameStatus
        }
        set {
          snapshot.updateValue(newValue, forKey: "gameStatus")
        }
      }

      public var winCondition: WinCondition? {
        get {
          return snapshot["winCondition"] as? WinCondition
        }
        set {
          snapshot.updateValue(newValue, forKey: "winCondition")
        }
      }

      public var maxScore: Int? {
        get {
          return snapshot["maxScore"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "maxScore")
        }
      }

      public var maxRounds: Int? {
        get {
          return snapshot["maxRounds"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "maxRounds")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }
    }
  }
}

public final class OnUpdateGameSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnUpdateGame($filter: ModelSubscriptionGameFilterInput, $owner: String) {\n  onUpdateGame(filter: $filter, owner: $owner) {\n    __typename\n    id\n    gameName\n    hostUserID\n    playerIDs\n    rounds\n    customRules\n    finalScores\n    gameStatus\n    winCondition\n    maxScore\n    maxRounds\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var filter: ModelSubscriptionGameFilterInput?
  public var owner: String?

  public init(filter: ModelSubscriptionGameFilterInput? = nil, owner: String? = nil) {
    self.filter = filter
    self.owner = owner
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "owner": owner]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onUpdateGame", arguments: ["filter": GraphQLVariable("filter"), "owner": GraphQLVariable("owner")], type: .object(OnUpdateGame.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onUpdateGame: OnUpdateGame? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onUpdateGame": onUpdateGame.flatMap { $0.snapshot }])
    }

    public var onUpdateGame: OnUpdateGame? {
      get {
        return (snapshot["onUpdateGame"] as? Snapshot).flatMap { OnUpdateGame(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onUpdateGame")
      }
    }

    public struct OnUpdateGame: GraphQLSelectionSet {
      public static let possibleTypes = ["Game"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("gameName", type: .scalar(String.self)),
        GraphQLField("hostUserID", type: .nonNull(.scalar(String.self))),
        GraphQLField("playerIDs", type: .nonNull(.list(.nonNull(.scalar(String.self))))),
        GraphQLField("rounds", type: .nonNull(.scalar(Int.self))),
        GraphQLField("customRules", type: .scalar(String.self)),
        GraphQLField("finalScores", type: .nonNull(.list(.nonNull(.scalar(String.self))))),
        GraphQLField("gameStatus", type: .nonNull(.scalar(GameStatus.self))),
        GraphQLField("winCondition", type: .scalar(WinCondition.self)),
        GraphQLField("maxScore", type: .scalar(Int.self)),
        GraphQLField("maxRounds", type: .scalar(Int.self)),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, gameName: String? = nil, hostUserId: String, playerIDs: [String], rounds: Int, customRules: String? = nil, finalScores: [String], gameStatus: GameStatus, winCondition: WinCondition? = nil, maxScore: Int? = nil, maxRounds: Int? = nil, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "Game", "id": id, "gameName": gameName, "hostUserID": hostUserId, "playerIDs": playerIDs, "rounds": rounds, "customRules": customRules, "finalScores": finalScores, "gameStatus": gameStatus, "winCondition": winCondition, "maxScore": maxScore, "maxRounds": maxRounds, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var gameName: String? {
        get {
          return snapshot["gameName"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "gameName")
        }
      }

      public var hostUserId: String {
        get {
          return snapshot["hostUserID"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "hostUserID")
        }
      }

      public var playerIDs: [String] {
        get {
          return snapshot["playerIDs"]! as! [String]
        }
        set {
          snapshot.updateValue(newValue, forKey: "playerIDs")
        }
      }

      public var rounds: Int {
        get {
          return snapshot["rounds"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "rounds")
        }
      }

      public var customRules: String? {
        get {
          return snapshot["customRules"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "customRules")
        }
      }

      public var finalScores: [String] {
        get {
          return snapshot["finalScores"]! as! [String]
        }
        set {
          snapshot.updateValue(newValue, forKey: "finalScores")
        }
      }

      public var gameStatus: GameStatus {
        get {
          return snapshot["gameStatus"]! as! GameStatus
        }
        set {
          snapshot.updateValue(newValue, forKey: "gameStatus")
        }
      }

      public var winCondition: WinCondition? {
        get {
          return snapshot["winCondition"] as? WinCondition
        }
        set {
          snapshot.updateValue(newValue, forKey: "winCondition")
        }
      }

      public var maxScore: Int? {
        get {
          return snapshot["maxScore"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "maxScore")
        }
      }

      public var maxRounds: Int? {
        get {
          return snapshot["maxRounds"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "maxRounds")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }
    }
  }
}

public final class OnDeleteGameSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnDeleteGame($filter: ModelSubscriptionGameFilterInput, $owner: String) {\n  onDeleteGame(filter: $filter, owner: $owner) {\n    __typename\n    id\n    gameName\n    hostUserID\n    playerIDs\n    rounds\n    customRules\n    finalScores\n    gameStatus\n    winCondition\n    maxScore\n    maxRounds\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var filter: ModelSubscriptionGameFilterInput?
  public var owner: String?

  public init(filter: ModelSubscriptionGameFilterInput? = nil, owner: String? = nil) {
    self.filter = filter
    self.owner = owner
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "owner": owner]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onDeleteGame", arguments: ["filter": GraphQLVariable("filter"), "owner": GraphQLVariable("owner")], type: .object(OnDeleteGame.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onDeleteGame: OnDeleteGame? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onDeleteGame": onDeleteGame.flatMap { $0.snapshot }])
    }

    public var onDeleteGame: OnDeleteGame? {
      get {
        return (snapshot["onDeleteGame"] as? Snapshot).flatMap { OnDeleteGame(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onDeleteGame")
      }
    }

    public struct OnDeleteGame: GraphQLSelectionSet {
      public static let possibleTypes = ["Game"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("gameName", type: .scalar(String.self)),
        GraphQLField("hostUserID", type: .nonNull(.scalar(String.self))),
        GraphQLField("playerIDs", type: .nonNull(.list(.nonNull(.scalar(String.self))))),
        GraphQLField("rounds", type: .nonNull(.scalar(Int.self))),
        GraphQLField("customRules", type: .scalar(String.self)),
        GraphQLField("finalScores", type: .nonNull(.list(.nonNull(.scalar(String.self))))),
        GraphQLField("gameStatus", type: .nonNull(.scalar(GameStatus.self))),
        GraphQLField("winCondition", type: .scalar(WinCondition.self)),
        GraphQLField("maxScore", type: .scalar(Int.self)),
        GraphQLField("maxRounds", type: .scalar(Int.self)),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, gameName: String? = nil, hostUserId: String, playerIDs: [String], rounds: Int, customRules: String? = nil, finalScores: [String], gameStatus: GameStatus, winCondition: WinCondition? = nil, maxScore: Int? = nil, maxRounds: Int? = nil, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "Game", "id": id, "gameName": gameName, "hostUserID": hostUserId, "playerIDs": playerIDs, "rounds": rounds, "customRules": customRules, "finalScores": finalScores, "gameStatus": gameStatus, "winCondition": winCondition, "maxScore": maxScore, "maxRounds": maxRounds, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var gameName: String? {
        get {
          return snapshot["gameName"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "gameName")
        }
      }

      public var hostUserId: String {
        get {
          return snapshot["hostUserID"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "hostUserID")
        }
      }

      public var playerIDs: [String] {
        get {
          return snapshot["playerIDs"]! as! [String]
        }
        set {
          snapshot.updateValue(newValue, forKey: "playerIDs")
        }
      }

      public var rounds: Int {
        get {
          return snapshot["rounds"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "rounds")
        }
      }

      public var customRules: String? {
        get {
          return snapshot["customRules"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "customRules")
        }
      }

      public var finalScores: [String] {
        get {
          return snapshot["finalScores"]! as! [String]
        }
        set {
          snapshot.updateValue(newValue, forKey: "finalScores")
        }
      }

      public var gameStatus: GameStatus {
        get {
          return snapshot["gameStatus"]! as! GameStatus
        }
        set {
          snapshot.updateValue(newValue, forKey: "gameStatus")
        }
      }

      public var winCondition: WinCondition? {
        get {
          return snapshot["winCondition"] as? WinCondition
        }
        set {
          snapshot.updateValue(newValue, forKey: "winCondition")
        }
      }

      public var maxScore: Int? {
        get {
          return snapshot["maxScore"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "maxScore")
        }
      }

      public var maxRounds: Int? {
        get {
          return snapshot["maxRounds"] as? Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "maxRounds")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }
    }
  }
}

public final class OnCreateScoreSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnCreateScore($filter: ModelSubscriptionScoreFilterInput, $owner: String) {\n  onCreateScore(filter: $filter, owner: $owner) {\n    __typename\n    id\n    gameID\n    playerID\n    roundNumber\n    score\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var filter: ModelSubscriptionScoreFilterInput?
  public var owner: String?

  public init(filter: ModelSubscriptionScoreFilterInput? = nil, owner: String? = nil) {
    self.filter = filter
    self.owner = owner
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "owner": owner]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onCreateScore", arguments: ["filter": GraphQLVariable("filter"), "owner": GraphQLVariable("owner")], type: .object(OnCreateScore.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onCreateScore: OnCreateScore? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onCreateScore": onCreateScore.flatMap { $0.snapshot }])
    }

    public var onCreateScore: OnCreateScore? {
      get {
        return (snapshot["onCreateScore"] as? Snapshot).flatMap { OnCreateScore(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onCreateScore")
      }
    }

    public struct OnCreateScore: GraphQLSelectionSet {
      public static let possibleTypes = ["Score"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("gameID", type: .nonNull(.scalar(String.self))),
        GraphQLField("playerID", type: .nonNull(.scalar(String.self))),
        GraphQLField("roundNumber", type: .nonNull(.scalar(Int.self))),
        GraphQLField("score", type: .nonNull(.scalar(Int.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, gameId: String, playerId: String, roundNumber: Int, score: Int, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "Score", "id": id, "gameID": gameId, "playerID": playerId, "roundNumber": roundNumber, "score": score, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var gameId: String {
        get {
          return snapshot["gameID"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "gameID")
        }
      }

      public var playerId: String {
        get {
          return snapshot["playerID"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "playerID")
        }
      }

      public var roundNumber: Int {
        get {
          return snapshot["roundNumber"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "roundNumber")
        }
      }

      public var score: Int {
        get {
          return snapshot["score"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "score")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }
    }
  }
}

public final class OnUpdateScoreSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnUpdateScore($filter: ModelSubscriptionScoreFilterInput, $owner: String) {\n  onUpdateScore(filter: $filter, owner: $owner) {\n    __typename\n    id\n    gameID\n    playerID\n    roundNumber\n    score\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var filter: ModelSubscriptionScoreFilterInput?
  public var owner: String?

  public init(filter: ModelSubscriptionScoreFilterInput? = nil, owner: String? = nil) {
    self.filter = filter
    self.owner = owner
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "owner": owner]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onUpdateScore", arguments: ["filter": GraphQLVariable("filter"), "owner": GraphQLVariable("owner")], type: .object(OnUpdateScore.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onUpdateScore: OnUpdateScore? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onUpdateScore": onUpdateScore.flatMap { $0.snapshot }])
    }

    public var onUpdateScore: OnUpdateScore? {
      get {
        return (snapshot["onUpdateScore"] as? Snapshot).flatMap { OnUpdateScore(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onUpdateScore")
      }
    }

    public struct OnUpdateScore: GraphQLSelectionSet {
      public static let possibleTypes = ["Score"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("gameID", type: .nonNull(.scalar(String.self))),
        GraphQLField("playerID", type: .nonNull(.scalar(String.self))),
        GraphQLField("roundNumber", type: .nonNull(.scalar(Int.self))),
        GraphQLField("score", type: .nonNull(.scalar(Int.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, gameId: String, playerId: String, roundNumber: Int, score: Int, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "Score", "id": id, "gameID": gameId, "playerID": playerId, "roundNumber": roundNumber, "score": score, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var gameId: String {
        get {
          return snapshot["gameID"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "gameID")
        }
      }

      public var playerId: String {
        get {
          return snapshot["playerID"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "playerID")
        }
      }

      public var roundNumber: Int {
        get {
          return snapshot["roundNumber"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "roundNumber")
        }
      }

      public var score: Int {
        get {
          return snapshot["score"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "score")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }
    }
  }
}

public final class OnDeleteScoreSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnDeleteScore($filter: ModelSubscriptionScoreFilterInput, $owner: String) {\n  onDeleteScore(filter: $filter, owner: $owner) {\n    __typename\n    id\n    gameID\n    playerID\n    roundNumber\n    score\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var filter: ModelSubscriptionScoreFilterInput?
  public var owner: String?

  public init(filter: ModelSubscriptionScoreFilterInput? = nil, owner: String? = nil) {
    self.filter = filter
    self.owner = owner
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "owner": owner]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onDeleteScore", arguments: ["filter": GraphQLVariable("filter"), "owner": GraphQLVariable("owner")], type: .object(OnDeleteScore.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onDeleteScore: OnDeleteScore? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onDeleteScore": onDeleteScore.flatMap { $0.snapshot }])
    }

    public var onDeleteScore: OnDeleteScore? {
      get {
        return (snapshot["onDeleteScore"] as? Snapshot).flatMap { OnDeleteScore(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onDeleteScore")
      }
    }

    public struct OnDeleteScore: GraphQLSelectionSet {
      public static let possibleTypes = ["Score"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("gameID", type: .nonNull(.scalar(String.self))),
        GraphQLField("playerID", type: .nonNull(.scalar(String.self))),
        GraphQLField("roundNumber", type: .nonNull(.scalar(Int.self))),
        GraphQLField("score", type: .nonNull(.scalar(Int.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, gameId: String, playerId: String, roundNumber: Int, score: Int, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "Score", "id": id, "gameID": gameId, "playerID": playerId, "roundNumber": roundNumber, "score": score, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var gameId: String {
        get {
          return snapshot["gameID"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "gameID")
        }
      }

      public var playerId: String {
        get {
          return snapshot["playerID"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "playerID")
        }
      }

      public var roundNumber: Int {
        get {
          return snapshot["roundNumber"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "roundNumber")
        }
      }

      public var score: Int {
        get {
          return snapshot["score"]! as! Int
        }
        set {
          snapshot.updateValue(newValue, forKey: "score")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }
    }
  }
}

public final class OnCreateUserSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnCreateUser($filter: ModelSubscriptionUserFilterInput, $owner: String) {\n  onCreateUser(filter: $filter, owner: $owner) {\n    __typename\n    id\n    username\n    email\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var filter: ModelSubscriptionUserFilterInput?
  public var owner: String?

  public init(filter: ModelSubscriptionUserFilterInput? = nil, owner: String? = nil) {
    self.filter = filter
    self.owner = owner
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "owner": owner]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onCreateUser", arguments: ["filter": GraphQLVariable("filter"), "owner": GraphQLVariable("owner")], type: .object(OnCreateUser.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onCreateUser: OnCreateUser? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onCreateUser": onCreateUser.flatMap { $0.snapshot }])
    }

    public var onCreateUser: OnCreateUser? {
      get {
        return (snapshot["onCreateUser"] as? Snapshot).flatMap { OnCreateUser(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onCreateUser")
      }
    }

    public struct OnCreateUser: GraphQLSelectionSet {
      public static let possibleTypes = ["User"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("username", type: .nonNull(.scalar(String.self))),
        GraphQLField("email", type: .nonNull(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, username: String, email: String, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "User", "id": id, "username": username, "email": email, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var username: String {
        get {
          return snapshot["username"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "username")
        }
      }

      public var email: String {
        get {
          return snapshot["email"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "email")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }
    }
  }
}

public final class OnUpdateUserSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnUpdateUser($filter: ModelSubscriptionUserFilterInput, $owner: String) {\n  onUpdateUser(filter: $filter, owner: $owner) {\n    __typename\n    id\n    username\n    email\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var filter: ModelSubscriptionUserFilterInput?
  public var owner: String?

  public init(filter: ModelSubscriptionUserFilterInput? = nil, owner: String? = nil) {
    self.filter = filter
    self.owner = owner
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "owner": owner]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onUpdateUser", arguments: ["filter": GraphQLVariable("filter"), "owner": GraphQLVariable("owner")], type: .object(OnUpdateUser.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onUpdateUser: OnUpdateUser? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onUpdateUser": onUpdateUser.flatMap { $0.snapshot }])
    }

    public var onUpdateUser: OnUpdateUser? {
      get {
        return (snapshot["onUpdateUser"] as? Snapshot).flatMap { OnUpdateUser(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onUpdateUser")
      }
    }

    public struct OnUpdateUser: GraphQLSelectionSet {
      public static let possibleTypes = ["User"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("username", type: .nonNull(.scalar(String.self))),
        GraphQLField("email", type: .nonNull(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, username: String, email: String, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "User", "id": id, "username": username, "email": email, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var username: String {
        get {
          return snapshot["username"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "username")
        }
      }

      public var email: String {
        get {
          return snapshot["email"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "email")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }
    }
  }
}

public final class OnDeleteUserSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnDeleteUser($filter: ModelSubscriptionUserFilterInput, $owner: String) {\n  onDeleteUser(filter: $filter, owner: $owner) {\n    __typename\n    id\n    username\n    email\n    createdAt\n    updatedAt\n    owner\n  }\n}"

  public var filter: ModelSubscriptionUserFilterInput?
  public var owner: String?

  public init(filter: ModelSubscriptionUserFilterInput? = nil, owner: String? = nil) {
    self.filter = filter
    self.owner = owner
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "owner": owner]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onDeleteUser", arguments: ["filter": GraphQLVariable("filter"), "owner": GraphQLVariable("owner")], type: .object(OnDeleteUser.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onDeleteUser: OnDeleteUser? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onDeleteUser": onDeleteUser.flatMap { $0.snapshot }])
    }

    public var onDeleteUser: OnDeleteUser? {
      get {
        return (snapshot["onDeleteUser"] as? Snapshot).flatMap { OnDeleteUser(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onDeleteUser")
      }
    }

    public struct OnDeleteUser: GraphQLSelectionSet {
      public static let possibleTypes = ["User"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("id", type: .nonNull(.scalar(GraphQLID.self))),
        GraphQLField("username", type: .nonNull(.scalar(String.self))),
        GraphQLField("email", type: .nonNull(.scalar(String.self))),
        GraphQLField("createdAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("updatedAt", type: .nonNull(.scalar(String.self))),
        GraphQLField("owner", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(id: GraphQLID, username: String, email: String, createdAt: String, updatedAt: String, owner: String? = nil) {
        self.init(snapshot: ["__typename": "User", "id": id, "username": username, "email": email, "createdAt": createdAt, "updatedAt": updatedAt, "owner": owner])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: GraphQLID {
        get {
          return snapshot["id"]! as! GraphQLID
        }
        set {
          snapshot.updateValue(newValue, forKey: "id")
        }
      }

      public var username: String {
        get {
          return snapshot["username"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "username")
        }
      }

      public var email: String {
        get {
          return snapshot["email"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "email")
        }
      }

      public var createdAt: String {
        get {
          return snapshot["createdAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "createdAt")
        }
      }

      public var updatedAt: String {
        get {
          return snapshot["updatedAt"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "updatedAt")
        }
      }

      public var owner: String? {
        get {
          return snapshot["owner"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "owner")
        }
      }
    }
  }
}
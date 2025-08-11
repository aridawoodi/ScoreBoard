// swiftlint:disable all
import Amplify
import Foundation

public struct User: Model {
  public let id: String
  public var username: String
  public var email: String
  public var createdAt: Temporal.DateTime
  public var updatedAt: Temporal.DateTime
  public var owner: String?
  
  public init(id: String = UUID().uuidString,
      username: String,
      email: String,
      createdAt: Temporal.DateTime,
      updatedAt: Temporal.DateTime,
      owner: String? = nil) {
      self.id = id
      self.username = username
      self.email = email
      self.createdAt = createdAt
      self.updatedAt = updatedAt
      self.owner = owner
  }
}
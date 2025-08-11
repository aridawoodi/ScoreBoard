// swiftlint:disable all
import Amplify
import Foundation

public struct Score: Model {
  public let id: String
  public var gameID: String
  public var playerID: String
  public var roundNumber: Int
  public var score: Int
  public var createdAt: Temporal.DateTime
  public var updatedAt: Temporal.DateTime
  public var owner: String?
  
  public init(id: String = UUID().uuidString,
      gameID: String,
      playerID: String,
      roundNumber: Int,
      score: Int,
      createdAt: Temporal.DateTime,
      updatedAt: Temporal.DateTime,
      owner: String? = nil) {
      self.id = id
      self.gameID = gameID
      self.playerID = playerID
      self.roundNumber = roundNumber
      self.score = score
      self.createdAt = createdAt
      self.updatedAt = updatedAt
      self.owner = owner
  }
}
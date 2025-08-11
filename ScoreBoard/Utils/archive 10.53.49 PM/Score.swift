// swiftlint:disable all
import Amplify
import Foundation

public struct Score: Model {
  public let id: String
  public var gameID: String
  public var roundNumber: Int
  public var playerID: String
  public var score: Int
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      gameID: String,
      roundNumber: Int,
      playerID: String,
      score: Int) {
    self.init(id: id,
      gameID: gameID,
      roundNumber: roundNumber,
      playerID: playerID,
      score: score,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      gameID: String,
      roundNumber: Int,
      playerID: String,
      score: Int,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.gameID = gameID
      self.roundNumber = roundNumber
      self.playerID = playerID
      self.score = score
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
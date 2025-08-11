// swiftlint:disable all
import Amplify
import Foundation

public struct Game: Model {
  public let id: String
  public var gameName: String?
  public var hostUserID: String
  public var playerIDs: [String]
  public var rounds: Int
  public var customRules: String?
  public var finalScores: [String]
  public var gameStatus: GameStatus
  public var createdAt: Temporal.DateTime
  public var updatedAt: Temporal.DateTime
  public var owner: String?
  
  public init(id: String = UUID().uuidString,
      gameName: String? = nil,
      hostUserID: String,
      playerIDs: [String] = [],
      rounds: Int,
      customRules: String? = nil,
      finalScores: [String] = [],
      gameStatus: GameStatus,
      createdAt: Temporal.DateTime,
      updatedAt: Temporal.DateTime,
      owner: String? = nil) {
      self.id = id
      self.gameName = gameName
      self.hostUserID = hostUserID
      self.playerIDs = playerIDs
      self.rounds = rounds
      self.customRules = customRules
      self.finalScores = finalScores
      self.gameStatus = gameStatus
      self.createdAt = createdAt
      self.updatedAt = updatedAt
      self.owner = owner
  }
}
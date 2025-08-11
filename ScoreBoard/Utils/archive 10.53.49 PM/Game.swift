// swiftlint:disable all
import Amplify
import Foundation

public struct Game: Model {
  public let id: String
  public var hostUserID: String
  public var playerIDs: [String] // Now always user IDs, non-optional
  public var rounds: Int
  public var customRules: String?
  public var finalScores: [String?]?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(id: String = UUID().uuidString,
      hostUserID: String,
      playerIDs: [String], // Non-optional
      rounds: Int,
      customRules: String? = nil,
      finalScores: [String?]? = nil) {
    self.init(id: id,
      hostUserID: hostUserID,
      playerIDs: playerIDs,
      rounds: rounds,
      customRules: customRules,
      finalScores: finalScores,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(id: String = UUID().uuidString,
      hostUserID: String,
      playerIDs: [String], // Non-optional
      rounds: Int,
      customRules: String? = nil,
      finalScores: [String?]? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.id = id
      self.hostUserID = hostUserID
      self.playerIDs = playerIDs
      self.rounds = rounds
      self.customRules = customRules
      self.finalScores = finalScores
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}
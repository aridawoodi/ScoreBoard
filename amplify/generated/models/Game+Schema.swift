// swiftlint:disable all
import Amplify
import Foundation

extension Game {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case gameName
    case hostUserID
    case playerIDs
    case rounds
    case customRules
    case finalScores
    case gameStatus
    case winCondition
    case maxScore
    case maxRounds
    case createdAt
    case updatedAt
    case owner
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let game = Game.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .public, operations: [.create, .read, .update, .delete])
    ]
    
    model.listPluralName = "Games"
    model.syncPluralName = "Games"
    
    model.attributes(
      .primaryKey(fields: [game.id])
    )
    
    model.fields(
      .field(game.id, is: .required, ofType: .string),
      .field(game.gameName, is: .optional, ofType: .string),
      .field(game.hostUserID, is: .required, ofType: .string),
      .field(game.playerIDs, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(game.rounds, is: .required, ofType: .int),
      .field(game.customRules, is: .optional, ofType: .string),
      .field(game.finalScores, is: .required, ofType: .embeddedCollection(of: String.self)),
      .field(game.gameStatus, is: .required, ofType: .enum(type: GameStatus.self)),
      .field(game.winCondition, is: .optional, ofType: .enum(type: WinCondition.self)),
      .field(game.maxScore, is: .optional, ofType: .int),
      .field(game.maxRounds, is: .optional, ofType: .int),
      .field(game.createdAt, is: .required, ofType: .dateTime),
      .field(game.updatedAt, is: .required, ofType: .dateTime),
      .field(game.owner, is: .optional, ofType: .string)
    )
    }
}

extension Game: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
// swiftlint:disable all
import Amplify
import Foundation

extension Game {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case hostUserID
    case playerIDs
    case rounds
    case customRules
    case finalScores
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let game = Game.keys
    
    model.authRules = [
      rule(allow: .public, operations: [.read]),
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete])
    ]
    
    model.listPluralName = "Games"
    model.syncPluralName = "Games"
    
    model.attributes(
      .primaryKey(fields: [game.id])
    )
    
    model.fields(
      .field(game.id, is: .required, ofType: .string),
      .field(game.hostUserID, is: .required, ofType: .string),
      .field(game.playerIDs, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(game.rounds, is: .required, ofType: .int),
      .field(game.customRules, is: .optional, ofType: .string),
      .field(game.finalScores, is: .optional, ofType: .embeddedCollection(of: String.self)),
      .field(game.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(game.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Game> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Game: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Game {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var hostUserID: FieldPath<String>   {
      string("hostUserID") 
    }
  public var playerIDs: FieldPath<String>   {
      string("playerIDs") 
    }
  public var rounds: FieldPath<Int>   {
      int("rounds") 
    }
  public var customRules: FieldPath<String>   {
      string("customRules") 
    }
  public var finalScores: FieldPath<String>   {
      string("finalScores") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}
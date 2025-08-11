// swiftlint:disable all
import Amplify
import Foundation

extension Score {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case gameID
    case roundNumber
    case playerID
    case score
    case createdAt
    case updatedAt
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let score = Score.keys
    
    model.authRules = [
      rule(allow: .public, operations: [.read]),
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete])
    ]
    
    model.listPluralName = "Scores"
    model.syncPluralName = "Scores"
    
    model.attributes(
      .primaryKey(fields: [score.id])
    )
    
    model.fields(
      .field(score.id, is: .required, ofType: .string),
      .field(score.gameID, is: .required, ofType: .string),
      .field(score.roundNumber, is: .required, ofType: .int),
      .field(score.playerID, is: .required, ofType: .string),
      .field(score.score, is: .required, ofType: .int),
      .field(score.createdAt, is: .optional, isReadOnly: true, ofType: .dateTime),
      .field(score.updatedAt, is: .optional, isReadOnly: true, ofType: .dateTime)
    )
    }
    public class Path: ModelPath<Score> { }
    
    public static var rootPath: PropertyContainerPath? { Path() }
}

extension Score: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
extension ModelPath where ModelType == Score {
  public var id: FieldPath<String>   {
      string("id") 
    }
  public var gameID: FieldPath<String>   {
      string("gameID") 
    }
  public var roundNumber: FieldPath<Int>   {
      int("roundNumber") 
    }
  public var playerID: FieldPath<String>   {
      string("playerID") 
    }
  public var score: FieldPath<Int>   {
      int("score") 
    }
  public var createdAt: FieldPath<Temporal.DateTime>   {
      datetime("createdAt") 
    }
  public var updatedAt: FieldPath<Temporal.DateTime>   {
      datetime("updatedAt") 
    }
}
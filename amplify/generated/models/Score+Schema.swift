// swiftlint:disable all
import Amplify
import Foundation

extension Score {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case gameID
    case playerID
    case roundNumber
    case score
    case createdAt
    case updatedAt
    case owner
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let score = Score.keys
    
    model.authRules = [
      rule(allow: .owner, ownerField: "owner", identityClaim: "cognito:username", provider: .userPools, operations: [.create, .update, .delete, .read]),
      rule(allow: .public, operations: [.create, .read, .update, .delete])
    ]
    
    model.listPluralName = "Scores"
    model.syncPluralName = "Scores"
    
    model.attributes(
      .primaryKey(fields: [score.id])
    )
    
    model.fields(
      .field(score.id, is: .required, ofType: .string),
      .field(score.gameID, is: .required, ofType: .string),
      .field(score.playerID, is: .required, ofType: .string),
      .field(score.roundNumber, is: .required, ofType: .int),
      .field(score.score, is: .required, ofType: .int),
      .field(score.createdAt, is: .required, ofType: .dateTime),
      .field(score.updatedAt, is: .required, ofType: .dateTime),
      .field(score.owner, is: .optional, ofType: .string)
    )
    }
}

extension Score: ModelIdentifiable {
  public typealias IdentifierFormat = ModelIdentifierFormat.Default
  public typealias IdentifierProtocol = DefaultModelIdentifier<Self>
}
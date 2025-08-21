// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "c4cefd4de61321a7b04924f32bdc35fd"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: Game.self)
    ModelRegistry.register(modelType: Score.self)
    ModelRegistry.register(modelType: User.self)
  }
}
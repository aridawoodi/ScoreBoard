// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "81eb01461b90e8cbd1eda8c5f8c8e18e"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: Game.self)
    ModelRegistry.register(modelType: Score.self)
    ModelRegistry.register(modelType: User.self)
  }
}
// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "677884d31f41bd4d63854226e5ccf3dd"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: Game.self)
    ModelRegistry.register(modelType: Score.self)
  }
}
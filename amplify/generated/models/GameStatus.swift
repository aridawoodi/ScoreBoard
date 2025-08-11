// swiftlint:disable all
import Amplify
import Foundation

public enum GameStatus: String, EnumPersistable {
  case active = "ACTIVE"
  case completed = "COMPLETED"
  case cancelled = "CANCELLED"
}
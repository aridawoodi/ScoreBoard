// swiftlint:disable all
import Amplify
import Foundation

public enum WinCondition: String, EnumPersistable {
  case highestScore = "HIGHEST_SCORE"
  case lowestScore = "LOWEST_SCORE"
}
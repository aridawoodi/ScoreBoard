import Foundation
import Amplify

class GameService {
    static let shared = GameService()
    
    private init() {}
    
    /// Delete a game and all its associated scores
    /// Only the game creator (hostUserID) can delete the game
    func deleteGame(_ game: Game, currentUserId: String) async -> Bool {
        // Check if current user is the game creator
        guard game.hostUserID == currentUserId else {
            print("🔍 DEBUG: User \(currentUserId) is not the creator of game \(game.id)")
            return false
        }
        
        do {
            print("🔍 DEBUG: ===== DELETE GAME START =====")
            print("🔍 DEBUG: Deleting game: \(game.id)")
            print("🔍 DEBUG: Game creator: \(game.hostUserID)")
            print("🔍 DEBUG: Current user: \(currentUserId)")
            
            // First, delete all scores associated with this game (server-side filtering)
            let scoresQuery = Score.keys.gameID.eq(game.id)
            let scoresResult = try await Amplify.API.query(request: .list(Score.self, where: scoresQuery))
            
            switch scoresResult {
            case .success(let gameScores):
                print("🔍 DEBUG: Found \(gameScores.count) scores to delete for game \(game.id)")
                
                // Delete all scores for this game
                for score in gameScores {
                    let deleteScoreResult = try await Amplify.API.mutate(request: .delete(score))
                    switch deleteScoreResult {
                    case .success(let deletedScore):
                        print("🔍 DEBUG: Successfully deleted score: \(deletedScore.id)")
                    case .failure(let error):
                        print("🔍 DEBUG: Failed to delete score \(score.id): \(error)")
                    }
                }
                
            case .failure(let error):
                print("🔍 DEBUG: Failed to fetch scores for deletion: \(error)")
            }
            
            // Now delete the game itself
            let deleteGameResult = try await Amplify.API.mutate(request: .delete(game))
            
            switch deleteGameResult {
            case .success(let deletedGame):
                print("🔍 DEBUG: Successfully deleted game: \(deletedGame.id)")
                print("🔍 DEBUG: ===== DELETE GAME END =====")
                return true
                
            case .failure(let error):
                print("🔍 DEBUG: Failed to delete game: \(error)")
                print("🔍 DEBUG: ===== DELETE GAME END (FAILED) =====")
                return false
            }
            
        } catch {
            print("🔍 DEBUG: Error deleting game: \(error)")
            print("🔍 DEBUG: ===== DELETE GAME END (ERROR) =====")
            return false
        }
    }
    
    /// Check if the current user is the creator of a game
    func isGameCreator(_ game: Game, currentUserId: String) -> Bool {
        return game.hostUserID == currentUserId
    }
}

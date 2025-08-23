import Foundation

// MARK: - Custom Rule Data Structure
struct CustomRule: Codable, Identifiable, Equatable {
    let id = UUID()
    let letter: String
    let value: Int
    
    init(letter: String, value: Int) {
        self.letter = letter.uppercased()
        self.value = value
    }
    
    // Custom coding keys to handle the id
    enum CodingKeys: String, CodingKey {
        case letter, value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        letter = try container.decode(String.self, forKey: .letter).uppercased()
        value = try container.decode(Int.self, forKey: .value)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(letter, forKey: .letter)
        try container.encode(value, forKey: .value)
    }
}

// MARK: - Custom Rules Manager
class CustomRulesManager {
    static let shared = CustomRulesManager()
    
    private init() {}
    
    // Convert custom rules array to JSON string for storage
    func rulesToJSON(_ rules: [CustomRule]) -> String? {
        do {
            let data = try JSONEncoder().encode(rules)
            return String(data: data, encoding: .utf8)
        } catch {
            print("🔍 DEBUG: Error encoding custom rules: \(error)")
            return nil
        }
    }
    
    // Convert JSON string back to custom rules array
    func jsonToRules(_ json: String?) -> [CustomRule] {
        guard let json = json, !json.isEmpty else { return [] }
        
        do {
            let data = json.data(using: .utf8)!
            let rules = try JSONDecoder().decode([CustomRule].self, from: data)
            return rules
        } catch {
            print("🔍 DEBUG: Error decoding custom rules: \(error)")
            return []
        }
    }
    
    // Convert display value to actual score
    func displayToScore(_ display: String, customRules: [CustomRule]) -> Int? {
        // First check if it's a custom rule letter
        if let rule = customRules.first(where: { $0.letter == display.uppercased() }) {
            return rule.value
        }
        
        // Otherwise try to parse as regular number
        return Int(display)
    }
    
    // Convert actual score to display value
    func scoreToDisplay(_ score: Int, customRules: [CustomRule]) -> String {
        // Check if there's a custom rule for this score
        if let rule = customRules.first(where: { $0.value == score }) {
            return rule.letter
        }
        
        // Otherwise return the score as string
        return String(score)
    }
    
    // Validate custom rules
    func validateRules(_ rules: [CustomRule]) -> (isValid: Bool, errorMessage: String?) {
        // Check for duplicate letters
        let letters = rules.map { $0.letter }
        let uniqueLetters = Set(letters)
        if letters.count != uniqueLetters.count {
            return (false, "Duplicate letters found in custom rules")
        }
        
        // Check for invalid letters (only allow single uppercase letters)
        for rule in rules {
            if rule.letter.count != 1 || rule.letter.range(of: "^[A-Z]$", options: .regularExpression, range: nil, locale: nil) == nil {
                return (false, "Custom rules must use single uppercase letters (A-Z)")
            }
        }
        
        // Check for duplicate values
        let values = rules.map { $0.value }
        let uniqueValues = Set(values)
        if values.count != uniqueValues.count {
            return (false, "Duplicate values found in custom rules")
        }
        
        return (true, nil)
    }
}

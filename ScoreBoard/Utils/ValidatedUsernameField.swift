//
//  ValidatedUsernameField.swift
//  ScoreBoard
//
//  Reusable validated username input field with real-time validation,
//  uniqueness checking, and smart suggestions.
//

import SwiftUI

struct ValidatedUsernameField: View {
    // MARK: - Bindings (Required)
    
    @Binding var username: String
    @Binding var isValid: Bool
    
    // MARK: - Configuration (Optional)
    
    var showHelperText: Bool = true
    var showSuggestions: Bool = true
    var showCharacterCount: Bool = true
    var placeholder: String = "Enter username"
    var currentUserId: String? = nil  // To exclude current user from uniqueness check
    
    // MARK: - Internal State
    
    @State private var validationResult: UsernameValidationResult?
    @State private var isValidating: Bool = false
    @State private var showingSuggestions: Bool = false
    @State private var hasStartedTyping: Bool = false
    
    // MARK: - Services
    
    private let validationService = UsernameValidationService.shared
    private let debouncer = ValidationDebouncer(delay: 0.5)
    
    // MARK: - Computed Properties
    
    private var showValidationFeedback: Bool {
        hasStartedTyping && !username.isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Username field with indicator
            HStack(spacing: 12) {
                TextField("", text: $username)
                    .modifier(AppTextFieldStyle(
                        placeholder: placeholder,
                        text: $username
                    ))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onChange(of: username) { _, newValue in
                        handleUsernameChange(newValue)
                    }
                
                // Validation indicator
                if showValidationFeedback {
                    validationIndicator
                        .frame(width: 24, height: 24)
                }
            }
            
            // Character count
            if showCharacterCount {
                HStack {
                    Text("\(username.count)/20")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Spacer()
                }
            }
            
            // Validation message
            if showValidationFeedback, let result = validationResult {
                validationMessageView(result: result)
            }
            
            // Username suggestions
            if showSuggestions && showingSuggestions, let result = validationResult, !result.suggestions.isEmpty {
                suggestionChipsView(suggestions: result.suggestions)
            }
            
            // Helper text
            if showHelperText && (!hasStartedTyping || username.isEmpty) {
                helperTextView()
            }
        }
    }
    
    // MARK: - Validation Indicator
    
    private var validationIndicator: some View {
        Group {
            if isValidating {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color("LightGreen")))
                    .scaleEffect(0.8)
            } else if let result = validationResult {
                Image(systemName: result.isValid && result.isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.isValid && result.isAvailable ? Color("LightGreen") : .red)
                    .font(.system(size: 20))
            }
        }
    }
    
    // MARK: - Validation Message View
    
    private func validationMessageView(result: UsernameValidationResult) -> some View {
        HStack(spacing: 8) {
            Image(systemName: messageIcon(for: result.messageType))
                .foregroundColor(messageColor(for: result.messageType))
                .font(.caption)
            
            Text(result.message)
                .font(.caption)
                .foregroundColor(messageColor(for: result.messageType))
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(messageBackgroundColor(for: result.messageType))
        .cornerRadius(8)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
    
    private func messageIcon(for type: UsernameValidationResult.ValidationMessageType) -> String {
        switch type {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    private func messageColor(for type: UsernameValidationResult.ValidationMessageType) -> Color {
        switch type {
        case .success: return Color("LightGreen")
        case .error: return .red
        case .info: return .blue
        }
    }
    
    private func messageBackgroundColor(for type: UsernameValidationResult.ValidationMessageType) -> Color {
        switch type {
        case .success: return Color("LightGreen").opacity(0.2)
        case .error: return Color.red.opacity(0.2)
        case .info: return Color.blue.opacity(0.2)
        }
    }
    
    // MARK: - Suggestion Chips View
    
    private func suggestionChipsView(suggestions: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Color("LightGreen"))
                    .font(.caption)
                
                Text("Try these instead:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Suggestion chips with wrapping
            FlowLayout(spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(action: {
                        selectSuggestion(suggestion)
                    }) {
                        HStack(spacing: 4) {
                            Text(suggestion)
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color("LightGreen").opacity(0.3))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color("LightGreen"), lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // MARK: - Helper Text View
    
    private func helperTextView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color("LightGreen"))
                    .font(.caption)
                Text("3-20 characters")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color("LightGreen"))
                    .font(.caption)
                Text("Letters, numbers, and underscores only")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color("LightGreen"))
                    .font(.caption)
                Text("Must start with a letter")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    // MARK: - Validation Logic
    
    private func handleUsernameChange(_ newValue: String) {
        print("🔍 DEBUG: ValidatedUsernameField - Username changed to: '\(newValue)'")
        
        if !hasStartedTyping && !newValue.isEmpty {
            hasStartedTyping = true
        }
        
        // Cancel any pending validation
        debouncer.cancel()
        
        // Quick format-only validation (instant)
        let formatResult = validationService.validateFormatOnly(newValue)
        
        if newValue.isEmpty {
            validationResult = nil
            showingSuggestions = false
            isValid = false
            return
        }
        
        if !formatResult.isValid {
            // Show format error immediately (no API call)
            validationResult = formatResult
            showingSuggestions = false
            isValidating = false
            isValid = false
            return
        }
        
        // Format is valid, now check availability with debounce
        isValidating = true
        showingSuggestions = false
        isValid = false  // Not validated yet
        
        debouncer.debounce {
            Task {
                print("🔍 DEBUG: ValidatedUsernameField - Starting full validation for: '\(newValue)'")
                let result = await validationService.validateUsername(newValue)
                
                await MainActor.run {
                    print("🔍 DEBUG: ValidatedUsernameField - Validation result: \(result.message)")
                    validationResult = result
                    isValidating = false
                    
                    // Update parent's isValid binding
                    isValid = result.isValid && result.isAvailable
                    
                    // Show suggestions if username is taken
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingSuggestions = !result.isAvailable && !result.suggestions.isEmpty
                    }
                }
            }
        }
    }
    
    private func selectSuggestion(_ suggestion: String) {
        print("🔍 DEBUG: ValidatedUsernameField - Selected suggestion: '\(suggestion)'")
        
        withAnimation {
            username = suggestion
            showingSuggestions = false
        }
        
        // Trigger validation for the selected suggestion
        handleUsernameChange(suggestion)
    }
}

// MARK: - FlowLayout for Suggestion Chips

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var username = ""
    @Previewable @State var isValid = false
    
    VStack {
        Text("Is Valid: \(isValid ? "✓" : "✗")")
            .foregroundColor(isValid ? .green : .red)
        
        ValidatedUsernameField(
            username: $username,
            isValid: $isValid,
            showHelperText: true,
            showSuggestions: true,
            showCharacterCount: true
        )
        .padding()
    }
    .gradientBackground()
}


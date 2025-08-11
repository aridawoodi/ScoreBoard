# Onboarding

This folder contains all onboarding-related components for the ScoreBoard app.

## Files

### OnboardingTooltip.swift
A reusable tooltip component that provides guided onboarding for new users. Features:
- Animated popup with semi-transparent overlay
- Customizable title, message, and action buttons
- Smooth spring animations
- Tap outside to dismiss functionality

### OnboardingManager.swift
Manages the onboarding state and user preferences. Features:
- Tracks whether user has seen onboarding using UserDefaults
- Provides methods to mark onboarding as seen or reset it
- Centralized management of onboarding state

### OnboardingConstants.swift
Centralizes all onboarding-related strings and configurations. Features:
- Tooltip messages and titles
- Button text constants
- Animation duration constants
- UserDefaults keys

## Usage

The onboarding system is integrated into the main tab views:
- **YourBoardTabView**: Shows tooltip when user has no games
- **CreateScoreboardTabView**: Shows guidance for creating games
- **JoinScoreboardTabView**: Shows guidance for joining games

## Testing

Use the "Reset Onboarding" option in the Profile tab to test the onboarding flow again.

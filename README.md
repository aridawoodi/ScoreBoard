# ScoreBoard

A modern iOS scoreboard application built with SwiftUI and AWS Amplify, designed for tracking scores across multiple games and players with real-time synchronization.

## Features

### 🎮 Game Management
- **Create Games**: Set up custom games with multiple players and rounds
- **Join Games**: Join existing games using game codes
- **Real-time Updates**: Live score synchronization across all connected devices
- **Game History**: View completed games and track player performance

### 👥 Player Management
- **Multiple Player Types**: Support for registered users and anonymous players
- **Player Analytics**: Track individual player statistics and performance
- **Guest Mode**: Play without creating an account
- **User Profiles**: Customizable player profiles with display names

### 📊 Analytics & Tracking
- **Player Statistics**: Comprehensive analytics for individual players
- **Game Analytics**: Track game performance and trends
- **Leaderboards**: Compare scores across different games and players
- **Historical Data**: Access to past game results and statistics

### 🔐 Authentication
- **AWS Cognito Integration**: Secure user authentication
- **Guest Mode**: Play without registration
- **Session Management**: Persistent login sessions
- **User Profiles**: Manage personal information and preferences

## Technology Stack

- **Frontend**: SwiftUI, iOS 15+
- **Backend**: AWS Amplify
- **Authentication**: AWS Cognito
- **Database**: AWS AppSync (GraphQL)
- **Real-time**: GraphQL Subscriptions
- **Storage**: AWS S3 (for user assets)

## Project Structure

```
ScoreBoard/
├── ScoreBoard/                    # Main iOS app
│   ├── Models/                    # Data models
│   ├── Network/                   # API services
│   ├── Utils/                     # Utilities and helpers
│   ├── ViewModels/                # MVVM view models
│   ├── Views/                     # SwiftUI views
│   │   ├── Authentication/        # Login/signup views
│   │   ├── GameSetup/            # Game creation and joining
│   │   ├── ScoreboardView/       # Main game interface
│   │   ├── Analytics/            # Player analytics
│   │   ├── Profile/              # User profile management
│   │   └── Tabs/                 # Tab navigation
│   └── Assets.xcassets/          # App assets and colors
├── amplify/                      # AWS Amplify configuration
├── graphql/                      # GraphQL schema and operations
└── README.md                     # This file
```

## Getting Started

### Prerequisites

- Xcode 14.0 or later
- iOS 15.0 or later
- AWS Account with Amplify CLI configured
- Node.js (for Amplify CLI)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ScoreBoard
   ```

2. **Install Amplify CLI** (if not already installed)
   ```bash
   npm install -g @aws-amplify/cli
   amplify configure
   ```

3. **Initialize Amplify** (if backend not already set up)
   ```bash
   amplify init
   amplify push
   ```

4. **Open in Xcode**
   ```bash
   open ScoreBoard.xcodeproj
   ```

5. **Build and Run**
   - Select your target device or simulator
   - Press `Cmd + R` to build and run

### Configuration

The app uses AWS Amplify for backend services. Ensure the following files are present and configured:

- `amplify_outputs.json` - Amplify configuration
- `amplifyconfiguration.json` - Legacy Amplify configuration
- `awsconfiguration.json` - AWS service configuration

## Usage

### Creating a Game

1. Open the app and sign in (or use guest mode)
2. Navigate to the "Create" tab
3. Set up game parameters:
   - Game name
   - Number of rounds
   - Player names
   - Win conditions
4. Share the game code with other players

### Joining a Game

1. Navigate to the "Join" tab
2. Enter the game code provided by the host
3. Enter your display name
4. Start playing immediately

### Tracking Scores

1. Select an active game from "Your Board"
2. Add scores for each round
3. View real-time updates as other players score
4. Track your progress and compare with other players

## Development

### Architecture

The app follows the MVVM (Model-View-ViewModel) pattern:

- **Models**: Data structures and business logic
- **Views**: SwiftUI user interface components
- **ViewModels**: Business logic and state management
- **Services**: Network and data management

### Key Components

- **DataManager**: Centralized data management and caching
- **AmplifyService**: AWS Amplify integration
- **NavigationState**: App-wide navigation state management
- **UserService**: User authentication and profile management

### Adding New Features

1. Create models in `Models/` directory
2. Add network services in `Network/` directory
3. Create view models in `ViewModels/` directory
4. Build SwiftUI views in `Views/` directory
5. Update navigation and state management as needed

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Support

For support and questions:

- Create an issue in the GitHub repository
- Check the [AWS Amplify documentation](https://docs.amplify.aws/)
- Review the [SwiftUI documentation](https://developer.apple.com/documentation/swiftui/)

## Acknowledgments

- Built with [AWS Amplify](https://aws.amazon.com/amplify/)
- UI framework: [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- Authentication: [AWS Cognito](https://aws.amazon.com/cognito/)
- Real-time data: [AWS AppSync](https://aws.amazon.com/appsync/)

---

**Created by Ari Dawoodi** - A modern scoreboard solution for iOS

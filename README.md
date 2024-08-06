# Pokemon API Client

This project demonstrates how to interact with the Pokémon API using Swift's Concurrency features and the Composable Architecture. The app allows users to search for Pokémon, view details about each Pokémon, and handle various network scenarios gracefully.

The app follows the Composable Architecture. It gives us a consistent manner to apply state mutations, instead of scattering logic in some observable objects and in various action closures of UI components. It also gives us a concise way of expressing side effects.

This is also the latest simplified version of composable archticture that uses the new swift observation tools.


## Libraries Used

### Swift Composable Architecture: https://github.com/pointfreeco/swift-composable-architecture

Composable architecture became very popular recently for it's basically swift adaption of the Redux framework that matches perfectly with SwiftUI and it follows a unidirectional data approach.

- **Why We Chose It**:
  - **State Management**: Provides a predictable way to manage state and side effects in a SwiftUI application. It allows for a clear separation of concerns and makes the code more maintainable and testable.
  - **Testability**: The architecture facilitates unit testing by enabling the creation of isolated and reproducible tests for state changes and side effects.
  - **Scalability**: Helps in scaling applications with complex state logic, as it structures the code in a modular way.

### Swift Concurrency (async/await)

- **Why I Chose It**:
  - **Asynchronous Code**: Simplifies writing asynchronous code by making it more readable and easier to manage, compared to traditional callback-based approaches.
  - **Error Handling**: Provides structured error handling in asynchronous contexts using Swift's `try/await` pattern, allowing for more robust error management.

## How to Build and Run the App

### Prerequisites

- **Xcode 15 or later**: Ensure you have the latest version of Xcode installed, as this project utilizes Swift's Concurrency features introduced in Swift 5.5.
- **Swift 5.5 or later**: Make sure your development environment is configured with Swift 5.5 or later.

### Steps to Build and Run

- **UnZip and run**: The app uses swift package manager so you will have to wait for xcode to install the dependencies after that you will be able to run the app.

# KDram

KDram is a social media platform developed for KDrama community. By signing users can find information on Korean Drama Television Series, update their KDrama watchlist and discover more KDrama that they might love. 

## Features

 - Sign Up/Sign In: Users sign up with their username which is linked to their personalized data including watch history, favorite KDramas, rankings, and the profiles bio. 
 - KDrama News: Provides a list of top KDramas from 2025 to 2018 displaying the cast, awards, number episodes, and genres. This tab also highlights the most popular KDrama actors/actresses displaying their accolades, KDrama's their featured in, direct link to their instagram, and more. 
 - Search Tool: Users can search KDrama's by name and toggle by type of genre, year released, and its available streaming serivce. This real-time filtering displays the scrollable images for users to discover more KDramas based on their preferences.
 - Library: Users can track all the KDrama's the've finished, currently watching, and their watchlist. In addition, their favorite KDrama actors and actresses are also displayed.
 - Social Account: Users can customize their profile page including their custom bio, profile picture, and their up-to-date finished KDrama's ranked using a tiered drag-and-drop diagram. Also with actions to save and reset their rankings for friends and family to actively view. 
 - Youtube & Spotify: Each Kdrama series is embedded with Youtube Trailers and provides users in accessing "Listen on Spotify" button for soundtracks. This feature enhance the multimedia experience within the app for users to have easy access to the KDramas we love. 
 - Expandable/Collapsible Sections: For better display, users can use "Show More" and "Show Less" for easier browsing throughout the KDrama platform.
 - Local Storage: Data is stored locally using .txt files loading user-specific content dynmically. 

## Technology Stack
 - Frontend: Flutter (Dart)
 - State Management: Stateful Widgets, Local File Handling
 - Backend/Storage: Local .txt Files (App Document Directory)
 - Multimedia: WebView (YouTube Embed), Spotify Integration
 - Authentication: Username-based local session
 - Platform Support: Android, iOS, iOS Simulator
 - Packages Used: webview_flutter (for embedded YouTube trailers), url_launcher (to open external Spotify/Instagram links), path_provider (for local file storage access), intl (for date/time formatting),
dart:io, dart:convert, dart:async (file operations and timing)

## Project Setup

### 1. Clone the repository
```bash
git clone https://github.com/your-username/KDramaApp.git
cd KDramaApp
```
### 2. Install Flutter dependencies
Be sure to have Flutter installed. Then run:
```bash
flutter pub get
```
### 4. Run the Application
```bash
flutter run
```

---

## License
This project was developed for personal and educational use. All rights reserved to the developer.
Please credit appropriately if using this project as a foundation.

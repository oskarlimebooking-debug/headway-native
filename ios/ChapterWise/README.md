# ChapterWise — Native iOS App

A full native SwiftUI iOS app for daily reading and learning. Import your PDF or EPUB books, let AI split them into chapters, and use 10 different learning modes to master the content.

## Features

### Book Management
- Import PDF and EPUB files
- AI-powered chapter detection and splitting (Gemini API)
- OCR support for scanned PDFs via Gemini Vision
- Custom book metadata (title, emoji, tags)
- Book cover image extraction from EPUBs
- Search, sort, and filter your library
- Multi-select for bulk operations

### 10 Learning Modes
1. **Read** — Clean, adjustable-size reading view with serif font
2. **Listen** — Text-to-speech with 3 provider options (Native/Lazybird/Google Cloud TTS)
3. **Summary** — AI-generated key concepts, simplified summary, difficulty rating
4. **Quiz** — Multiple choice, true/false, and open-ended questions with scoring
5. **Flashcards** — 3D flip-card animations for memorization
6. **Chat** — Ask the AI anything about the chapter
7. **Teach Back** — Explain what you learned, get Feynman-technique feedback
8. **Socratic** — Guided inquiry with progressive questioning
9. **Mind Map** — Visual hierarchical concept maps
10. **Feed** — Social media-style posts from 7 AI personalities

### Audio
- Native iOS TTS (AVSpeechSynthesizer)
- Lazybird TTS API integration
- Google Cloud TTS API integration
- Background audio playback with lock screen controls
- Persistent audio player bar
- Audio caching per chapter

### Cloud & Data
- Google Drive sync (appdata folder)
- JSON data export/import
- Reading streak tracking
- Daily suggestion engine

---

## Prerequisites

Before you begin, you need:

| Requirement | Version | Notes |
|---|---|---|
| **macOS** | 14.0+ (Sonoma) | Required for Xcode 15 |
| **Xcode** | 15.0+ | Free from Mac App Store |
| **iOS Device** | iOS 17.0+ | iPhone or iPad |
| **Apple ID** | Any | For free provisioning |
| **XcodeGen** | Latest | To generate the Xcode project |

### Install XcodeGen

XcodeGen generates the `.xcodeproj` from our `project.yml` configuration file.

```bash
# Using Homebrew (recommended)
brew install xcodegen

# Or using Mint
mint install yonaskolb/XcodeGen
```

### Get a Gemini API Key

The app uses Google's Gemini AI for chapter splitting, summaries, quizzes, and more.

1. Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Click **"Create API Key"**
3. Copy your key — you'll enter it in the app's Settings

---

## Building & Installing

### Step 1: Clone the Repository

```bash
git clone <your-repo-url>
cd Headway/ios/ChapterWise
```

### Step 2: Generate the Xcode Project

```bash
xcodegen generate
```

This creates `ChapterWise.xcodeproj` from `project.yml`.

### Step 3: Open in Xcode

```bash
open ChapterWise.xcodeproj
```

Or double-click `ChapterWise.xcodeproj` in Finder.

### Step 4: Configure Signing (Free Provisioning)

Since you don't have a paid Apple Developer account, you'll use **free provisioning**:

1. In Xcode, select the **ChapterWise** project in the navigator (blue icon)
2. Select the **ChapterWise** target
3. Go to the **"Signing & Capabilities"** tab
4. Check **"Automatically manage signing"**
5. For **Team**, select **"Add an Account..."**
   - Sign in with your Apple ID
   - Select your **Personal Team** (it will say "(Personal Team)")
6. If you see a bundle ID error, change it to something unique:
   - e.g., `com.yourname.chapterwise` (replace `yourname`)
7. Xcode should show a ✅ next to "Signing Certificate"

### Step 5: Connect Your Device

1. Connect your iPhone/iPad to your Mac with a USB cable
2. On your device: **Settings → General → Device Management**
   - If prompted, tap **"Trust This Computer"**
3. In Xcode's toolbar, click the device selector (top center) and choose your device
4. If this is your first time, wait for Xcode to prepare the device (may take a few minutes)

### Step 6: Build & Run

1. Press **⌘R** (Command + R) or click the **Play** button
2. Wait for the build to complete (first build takes 1-2 minutes)
3. The app will launch on your device

### Step 7: Trust the Developer Certificate

On first launch, iOS will show: *"Untrusted Developer"*

1. On your device: **Settings → General → VPN & Device Management**
2. Under **"Developer App"**, tap your Apple ID email
3. Tap **"Trust [your email]"**
4. Tap **"Trust"** to confirm
5. Go back and open ChapterWise

### Step 8: First-Run Setup

1. Tap the **⚙️ Settings** gear icon (top right)
2. Enter your **Gemini API Key**
3. (Optional) Configure TTS providers
4. Tap **Save**
5. Tap **+** to import your first book!

---

## Alternative: Manual Xcode Project Setup

If you prefer not to use XcodeGen, you can create the project manually:

1. Open Xcode → **File → New → Project**
2. Choose **iOS → App**
3. Set:
   - Product Name: `ChapterWise`
   - Bundle Identifier: `com.chapterwise.app`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **SwiftData**
4. Save the project, then delete the auto-generated files
5. Drag all files from `ChapterWise/` folder into the Xcode project navigator
6. In Build Settings, set deployment target to **iOS 17.0**
7. In Signing & Capabilities, add **Background Modes → Audio**
8. Build and run

---

## Troubleshooting

### "Untrusted Developer" Error
→ Go to **Settings → General → VPN & Device Management** on your device and trust the certificate. See Step 7 above.

### "No provisioning profile"
→ Make sure you signed in with your Apple ID in Xcode → Settings → Accounts, and selected your Personal Team.

### "Could not launch app" / App crashes on launch
→ Try: Clean Build Folder (**⇧⌘K**), then rebuild (**⌘R**).

### Free provisioning app expires after 7 days
→ This is a limitation of free Apple Developer accounts. After 7 days, the app will stop launching. Simply reconnect your device to your Mac and press ⌘R to reinstall. Your data is preserved (stored in the app's SwiftData container on the device).

### "Failed to generate..." / API errors
→ Check your Gemini API key in Settings. Make sure it's correct and you have API credits remaining.

### PDF text extraction issues
→ Some PDFs contain scanned images instead of text. When detected, the app will offer to use AI OCR (requires Gemini API key). This processes each page individually and may take a few minutes for long documents.

### EPUB parsing issues
→ Some EPUBs use non-standard structures. If chapters aren't detected properly, the app will fall back to AI-based or word-count splitting.

### No audio from TTS
→ Check that your device isn't on silent mode. For native TTS, ensure the device volume is up. For Lazybird/Google TTS, verify the API keys are correct in Settings.

### Build error: "Module not found"
→ Clean the build folder (**⇧⌘K**) and rebuild. Ensure your Xcode version is 15.0+.

---

## Project Architecture

```
ChapterWise/
├── ChapterWiseApp.swift          # App entry point with SwiftData container
├── ContentView.swift             # Root navigation + toast + persistent player
├── Info.plist                    # App configuration (background audio, URL schemes)
│
├── Models/                       # SwiftData @Model classes
│   ├── Book.swift                # Book with cover, tags, progress
│   ├── Chapter.swift             # Chapter with content, audio cache
│   ├── GeneratedContent.swift    # Cached AI outputs (summary, quiz, etc.)
│   ├── ReadingProgress.swift     # Daily reading streaks
│   └── AppSettings.swift         # Key-value settings store
│
├── Services/                     # Business logic & API clients
│   ├── GeminiService.swift       # All Gemini API calls (actor, thread-safe)
│   ├── PDFImportService.swift    # PDFKit text extraction + OCR
│   ├── EPUBImportService.swift   # ZIP + XML EPUB parsing
│   ├── TTSService.swift          # Native AVSpeechSynthesizer
│   ├── LazyBirdTTSService.swift  # Lazybird TTS API
│   ├── GoogleTTSService.swift    # Google Cloud TTS API
│   ├── AudioPlayerService.swift  # AVAudioPlayer + Now Playing
│   ├── GoogleDriveService.swift  # OAuth + Drive API sync
│   └── DataExportService.swift   # JSON export/import
│
├── ViewModels/                   # @Observable view models
│   ├── LibraryViewModel.swift    # Library search, sort, import
│   ├── BookDetailViewModel.swift # Chapter management, edits
│   ├── ReaderViewModel.swift     # 10 learning modes, content cache
│   ├── AudioViewModel.swift      # TTS generation & playback
│   └── SettingsViewModel.swift   # Settings persistence
│
├── Views/
│   ├── Library/                  # Main library grid
│   ├── BookDetail/               # Book info + chapter list
│   ├── Reader/                   # 10 learning mode views
│   ├── Settings/                 # App configuration
│   ├── Components/               # Reusable UI components
│   └── Import/                   # File import flow
│
└── Utilities/
    ├── Theme.swift               # Colors, gradients, fonts
    ├── Constants.swift           # API URLs, AI prompts
    └── Extensions.swift          # String, Date, View helpers
```

---

## Technology Stack

| Component | Technology |
|---|---|
| UI Framework | SwiftUI |
| Data Persistence | SwiftData (iOS 17+) |
| PDF Handling | PDFKit |
| EPUB Parsing | Foundation ZIP + XMLParser |
| AI Integration | Gemini API via URLSession |
| Native TTS | AVSpeechSynthesizer |
| Audio Playback | AVAudioPlayer + AVAudioSession |
| Lock Screen Controls | MPRemoteCommandCenter |
| OAuth | ASWebAuthenticationSession |
| Cloud Storage | Google Drive API v3 |

---

## License

MIT

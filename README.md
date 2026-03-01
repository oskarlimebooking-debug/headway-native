# ChapterWise — Daily Learning

A personal reading app that helps you learn something new every day. Upload your EPUB or PDF books, and the app will split them into chapters using AI, then provide various learning modes for each chapter.

## Features

### 📚 Book Management
- Upload EPUB and PDF files (up to 15MB)
- AI-powered chapter detection and splitting (using Gemini API)
- Progress tracking per book
- Daily reading suggestions

### 📖 Reading Modes
1. **Read** — Clean, mobile-friendly reading view
2. **Listen** — Text-to-speech with speed controls
3. **Summary** — AI-generated simplified version with key concepts
4. **Quiz** — Multiple choice, true/false, and open-ended questions
5. **Flashcards** — Flip cards for memorization
6. **Teach Back** — Explain what you learned, get AI feedback

### 📊 Progress Tracking
- Chapter completion tracking
- Daily streak counter
- Export your data as backup

## Setup

### 1. Get a Gemini API Key
1. Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Click "Create API Key"
3. Copy your key

### 2. Deploy to Vercel

**Option A: Using Vercel CLI**
```bash
npm install -g vercel
cd readwise-app
vercel
```

**Option B: Using Vercel Dashboard**
1. Push this folder to a GitHub repository
2. Go to [vercel.com](https://vercel.com)
3. Click "Import Project"
4. Select your repository
5. Deploy!

### 3. Deploy to Netlify

**Option A: Drag & Drop**
1. Go to [app.netlify.com/drop](https://app.netlify.com/drop)
2. Drag the `readwise-app` folder onto the page
3. Done!

**Option B: Using Netlify CLI**
```bash
npm install -g netlify-cli
cd readwise-app
netlify deploy --prod
```

### 4. Local Development
```bash
cd readwise-app
npx serve .
```
Then open http://localhost:3000

## Usage

1. **Open the app** and tap the ⚙️ settings button
2. **Enter your Gemini API key** and save
3. **Tap "Add Book"** and select an EPUB or PDF file
4. **Wait for AI processing** (this may take a minute for large books)
5. **Open the book** and start reading chapters!

## Technical Details

### Storage
- All data is stored locally in IndexedDB
- Books, chapters, and generated content persist across sessions
- Export feature creates a JSON backup of all your data

### AI Integration
- Uses Google's Gemini 1.5 Flash model
- Chapter splitting is done by AI analyzing document structure
- Summaries, quizzes, and flashcards are generated on-demand and cached

### PWA Features
- Installable on mobile devices
- Works offline (except AI features)
- Service worker caches assets

## File Structure
```
readwise-app/
├── index.html      # Main app (single-file PWA)
├── manifest.json   # PWA manifest
├── sw.js           # Service worker
├── package.json    # For deployment
└── README.md       # This file
```

## Future Improvements
- [ ] Cloud sync between devices
- [ ] Spaced repetition for flashcards
- [ ] Reading reminders (push notifications)
- [ ] Import/export to Anki
- [ ] Markdown export of summaries
- [ ] Highlighting and notes
- [ ] Better EPUB parsing with cover images

## Troubleshooting

**"Failed to generate..."**
- Check your Gemini API key is correct
- Make sure you have API credits remaining
- Try a smaller file

**PDF text extraction issues**
- Some PDFs have images instead of text (scanned books)
- Try an EPUB version if available

**Chapter splitting seems wrong**
- The AI does its best but complex books may need manual adjustment
- Consider uploading a cleaner EPUB version

## License
MIT

import Foundation

enum Constants {
    // MARK: - API Endpoints
    static let geminiBaseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    static let lazybirdBaseURL = "https://api.lazybird.app/v1"
    static let googleTTSBaseURL = "https://texttospeech.googleapis.com/v1"

    // MARK: - Default Model
    static let defaultModel = "gemini-2.5-flash"

    // MARK: - Available Models
    static let availableModels = [
        "gemini-2.5-flash",
        "gemini-2.5-pro",
        "gemini-2.0-flash",
        "gemini-1.5-flash",
        "gemini-1.5-pro"
    ]

    static let imageModels = [
        "gemini-2.0-flash-preview-image-generation",
        "imagen-3.0-generate-002"
    ]

    // MARK: - Mind Map Colors
    static let mindMapColors = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#FFA07A", "#98D8C8"]
}

// MARK: - AI Prompts
enum Prompts {
    static let chapterSplit = """
    You are an expert at analyzing books and documents to identify chapter/section boundaries.

    Book Title: "{{bookTitle}}"

    Book Content:
    {{content}}

    TASK: Analyze this text and identify where chapters/sections BEGIN. Return ONLY the chapter boundary information as JSON.

    DETECTION STRATEGY:
    1. EXPLICIT MARKERS (highest priority):
       - "Chapter X", "CHAPTER X", "Part X", "Section X"
       - Roman numerals: "I.", "II.", "III."
       - Numbered sections: "1.", "2.", "3."
       - Title case headings on their own line

    2. STRUCTURAL PATTERNS:
       - Blank lines followed by centered/bold text
       - Repeated formatting patterns
       - Major scene breaks (marked with *** or ---)

    3. CONTENT SHIFTS (if no explicit markers):
       - Major topic/theme changes
       - Time jumps in narrative
       - POV changes
       - New locations or settings

    CHAPTER SIZING GUIDELINES:
    - Ideal: 1500-4000 words per chapter
    - Minimum: 500 words (merge smaller sections)
    - Maximum: 6000 words (consider splitting)
    - Aim for 5-20 chapters for typical books

    OUTPUT FORMAT:
    Return a JSON array where each object represents a chapter with:
    - "title": A descriptive title for this chapter
    - "startMarker": The EXACT first 10-15 words that begin this chapter (copy exactly from the text)

    Example:
    [
      {"title": "Introduction: The Beginning", "startMarker": "In the beginning, there was only darkness and the"},
      {"title": "Chapter 1: The Journey Begins", "startMarker": "The morning sun rose slowly over the mountains as"},
      {"title": "Chapter 2: New Discoveries", "startMarker": "Three weeks had passed since the journey began when"}
    ]

    IMPORTANT:
    - The startMarker MUST be copied EXACTLY from the text (first 10-15 words)
    - The first chapter should always start at the beginning of the text
    - Include ALL chapters - don't miss any structural divisions
    - Return ONLY the JSON array, no other text or markdown
    - Use descriptive titles that reflect the content
    """

    static let summary = """
    Summarize this chapter for a learning app. Be concise but comprehensive.

    Chapter: "{{chapterTitle}}"

    Content:
    {{content}}

    Provide:
    1. 3-5 key concepts (as short phrases)
    2. A simplified summary (2-3 paragraphs, easy to understand)
    3. Difficulty rating (1-5, where 1 is easy and 5 is very complex)
    4. Estimated reading time in minutes for the original (assume 200 words/minute)

    Return as JSON:
    {
      "keyConcepts": ["concept1", "concept2"],
      "summary": "The simplified summary...",
      "difficulty": 3,
      "readingTime": 10
    }

    Return ONLY the JSON, no other text.
    """

    static let quiz = """
    Create a quiz for this chapter to test comprehension.

    Chapter: "{{chapterTitle}}"

    Content:
    {{content}}

    Create 5 questions:
    - 3 multiple choice questions
    - 1 true/false question
    - 1 open-ended reflection question

    Return as JSON:
    {
      "questions": [
        {
          "type": "multiple_choice",
          "question": "The question text?",
          "options": ["A) Option 1", "B) Option 2", "C) Option 3", "D) Option 4"],
          "correctIndex": 0,
          "explanation": "Why this is correct..."
        },
        {
          "type": "true_false",
          "question": "Statement to evaluate?",
          "correct": true,
          "explanation": "Why this is true/false..."
        },
        {
          "type": "open_ended",
          "question": "Reflection question?",
          "sampleAnswer": "A good answer might include..."
        }
      ]
    }

    Return ONLY the JSON, no other text.
    """

    static let flashcards = """
    Create flashcards for this chapter to aid memorization and learning.

    Chapter: "{{chapterTitle}}"

    Content:
    {{content}}

    Create 5-8 flashcards with:
    - Front: A question, term, or concept
    - Back: The answer, definition, or explanation

    Return as JSON:
    {
      "flashcards": [
        {
          "front": "What is...?",
          "back": "The answer is..."
        }
      ]
    }

    Return ONLY the JSON, no other text.
    """

    static let teachback = """
    You are evaluating a student's explanation of a chapter using the Feynman technique.

    Chapter: "{{chapterTitle}}"

    Original Content Summary:
    {{content}}

    Student's Explanation:
    "{{userExplanation}}"

    Evaluate their understanding:
    1. What did they explain well?
    2. What key points did they miss or misunderstand?
    3. Suggestions for improvement
    4. Overall score (1-10)

    Return as JSON:
    {
      "strengths": "What they explained well...",
      "gaps": "What they missed or got wrong...",
      "suggestions": "How to improve understanding...",
      "score": 7
    }

    Return ONLY the JSON, no other text.
    """

    static let mindmap = """
    You are an expert at creating structured mind maps for visual learning.

    Chapter: "{{chapterTitle}}"

    Content:
    {{content}}

    Create a hierarchical mind map structure showing:
    1. Central concept (the chapter title or main theme)
    2. 3-5 main branches (key themes/sections)
    3. 2-4 sub-branches per main branch (supporting ideas)
    4. Leaf nodes with specific details/examples

    Return as JSON:
    {
      "center": "Main Chapter Topic",
      "branches": [
        {
          "title": "Main Theme 1",
          "color": "#FF6B6B",
          "subbranches": [
            {
              "title": "Subtopic 1.1",
              "items": ["detail 1", "detail 2", "detail 3"]
            },
            {
              "title": "Subtopic 1.2",
              "items": ["detail 1", "detail 2"]
            }
          ]
        },
        {
          "title": "Main Theme 2",
          "color": "#4ECDC4",
          "subbranches": []
        }
      ]
    }

    Use these colors for branches (in order): #FF6B6B, #4ECDC4, #45B7D1, #FFA07A, #98D8C8

    Return ONLY the JSON, no other text.
    """

    static let socratic = """
    You are a Socratic tutor guiding a student through understanding this chapter.

    Chapter: "{{chapterTitle}}"

    Content:
    {{content}}

    Conversation so far:
    {{history}}

    Ask a thought-provoking question that:
    1. Builds on the student's previous answers
    2. Guides them toward deeper understanding
    3. Doesn't give away answers directly
    4. Encourages critical thinking

    If this is the start, ask an opening question about a core concept.

    Return as JSON:
    {
      "question": "Your Socratic question here?",
      "hint": "A subtle hint if they struggle...",
      "keyInsight": "The insight you're guiding them toward..."
    }

    Return ONLY the JSON, no other text.
    """

    static let feed = """
    You are generating a social media feed that teaches through entertainment. Each post comes from a DIFFERENT personality with a DISTINCT voice.

    Chapter: "{{chapterTitle}}"

    Content:
    {{content}}

    Create 20 social media posts covering DIFFERENT aspects of this chapter. NO CHARACTER LIMITS - posts can be as long as needed.

    PERSONALITY TYPES (use ALL of these):
    1. THE PROFESSOR (3-4 posts) - Academic but accessible, drops citations casually
    2. THE HYPE BEAST (2-3 posts) - CAPS LOCK ENERGY, lots of emojis, inspirational
    3. THE CONTRARIAN (3-4 posts) - "Unpopular opinion but...", challenges conventional wisdom
    4. THE UNHINGED (2-3 posts) - Chaotic energy, memes, Gen-Z energy, lowercase
    5. THE NURTURING EXPLAINER (2-3 posts) - Warm, patient, uses everyday analogies
    6. THE STORYTELLER (2-3 posts) - Personal anecdotes, narrative hooks
    7. THE MEME LORD (2-3 posts) - Pure comedy, pop culture references

    USERNAME STYLE BY PERSONALITY:
    - Professor: "Dr.Actually", "Prof_Citations", "AcademicAlan", "PhD_Thoughts"
    - Hype: "GrindsetGuru", "LevelUpLarry", "BeastModeBooks", "10X_Learner"
    - Contrarian: "WellActually", "DevilsAdvocate", "HotTakeHenry", "Counterpoint_"
    - Unhinged: "chaotic_learner", "brainrot_edu", "nochill_scholar", "unhinged_phd"
    - Nurturing: "GentleGenius", "LearnWithLove", "PatientProf", "KindMind"
    - Storyteller: "TalesOfWisdom", "StoryNerd", "NarrativeNick", "PlotTwistPaul"
    - Meme: "EducatedClown", "BrainGooBrrr", "MemePhD", "TouchedGrass"

    Return as JSON:
    {
      "posts": [
        {
          "id": 1,
          "username": "Username",
          "handle": "@handle",
          "avatar": "relevant emoji",
          "personality": "professor|hype|contrarian|unhinged|nurturing|storyteller|meme",
          "content": "The full post content with #hashtags",
          "likes": 1234,
          "retweets": 567,
          "views": 89000,
          "isViral": false,
          "hasImage": false,
          "imagePrompt": "",
          "hasLink": false,
          "linkTopic": ""
        }
      ]
    }

    Return ONLY valid JSON, no markdown or other text.
    """

    static let formatText = """
    You are a text formatting and cleaning expert. Clean the text of artifacts AND add proper formatting for optimal readability.

    Chapter: "{{chapterTitle}}"

    Raw text:
    {{content}}

    STEP 1 - REMOVE ARTIFACTS:
    - Page numbers, headers/footers that repeat
    - URLs, copyright notices, ISBN numbers
    - Scanner/OCR artifacts, excessive whitespace

    STEP 2 - FORMAT:
    - Preserve paragraph breaks
    - Clean up spacing
    - Fix hyphenation from line breaks

    CRITICAL: Keep ALL meaningful content. Do NOT summarize or rephrase.

    Return ONLY the clean text. No explanations or markdown code blocks.
    """

    static let ttsClean = """
    You are a text cleaning expert preparing text for text-to-speech playback.

    Text content:
    {{content}}

    REMOVE these elements that disrupt audio:
    1. Citations: (Author, Year), [1], superscript numbers
    2. Academic artifacts: "See page X", table/figure references
    3. Formatting artifacts: page numbers, headers/footers, URLs
    4. OCR artifacts: split words, wrong spacing

    PRESERVE: All actual content, headings, lists, quotes, dialogue.

    CRITICAL: Do NOT summarize or rephrase. Return plain text only.

    Return ONLY the cleaned text. No explanations or markdown code blocks.
    """

    static let ocrClean = """
    You are a text cleaning expert fixing OCR artifacts from PDF imports.

    Raw text from PDF:
    {{content}}

    Fix: page headers/footers, publication metadata, page break artifacts, split words, hyphenation at line breaks, spacing errors, common OCR typos, formatting issues.

    IMPORTANT: Preserve ALL citations, preserve ALL content, only fix errors and remove clutter. Return plain text only.

    Return ONLY the cleaned text. No explanations or markdown code blocks.
    """

    static let chunkBoundary = """
    Analyze this text excerpt and find ALL chapter/section boundaries.

    Book: "{{bookTitle}}"
    Text excerpt (chunk {{chunkIndex}}):
    {{content}}

    TASK: Identify where new chapters or major sections BEGIN.

    Look for:
    1. Explicit chapter markers: "Chapter X", "Part X", "Section X"
    2. Roman numerals or numbers on their own line
    3. Major headings or title-case text on its own line
    4. Clear thematic/topical breaks
    5. Scene breaks marked with "***" or "---"

    For each boundary:
    - "position": Approximate character position within this chunk
    - "title": A descriptive title
    - "firstWords": The EXACT first 15-20 words that start this section

    Return as JSON array:
    [
      {"position": 0, "title": "Introduction", "firstWords": "The story begins with a young..."}
    ]

    If no clear boundaries found, return: []
    Return ONLY the JSON array, no other text.
    """

    static let enhanceTitles = """
    Book: "{{bookTitle}}"

    I detected {{chapterCount}} chapters with these titles:
    {{chapterList}}

    Please suggest better, more descriptive titles for each chapter based on the content preview.
    Return ONLY a JSON array of improved titles in the same order:
    ["Improved Title 1", "Improved Title 2", ...]
    """
}

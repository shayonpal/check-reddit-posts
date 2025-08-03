# Reddit Post Analyzer

A bash script that fetches posts from Reddit subreddits and uses OpenAI's GPT-4.1-mini to analyze business opportunities, pain points, and user sentiment with enhanced comment analysis.

## Description

This tool automates the process of:
- Fetching top posts from specified subreddits using Reddit's OAuth API
- Filtering posts by age and content criteria
- **Fetching and analyzing top comments for each post** to identify solutions and community validation
- Analyzing each post with OpenAI to extract pain points and business opportunities
- Performing enhanced sentiment analysis (unsolved problems, feature requests, pain validation, etc.)
- **Scoring business opportunities (1-5 scale)** based on problem severity and solution status
- Generating timestamped JSON summaries with detailed metadata
- **Creating markdown analysis reports** with business insights by community
- Tracking API usage and costs

## Features

- **Multi-subreddit support**: Analyze posts from multiple subreddits in a single run
- **Flexible ordering**: Supports hot, new, top, rising, and controversial post ordering
- **Time-based filtering**: Filter posts by age and timeframe (hour/day/week/month/year)
- **Comment analysis**: Fetches top 10 comments per post to identify existing solutions
- **Business opportunity scoring**: Rates each post's potential (1-5 scale)
- **Enhanced sentiment classification**: 
  - `unsolved_problem`: Problems with no working solutions
  - `partial_solution`: Has workarounds but they're complex/incomplete
  - `seeking_tool`: Actively looking for a tool that doesn't exist
  - `feature_request`: Wants functionality not in current tools
  - `pain_validated`: Multiple people have the same problem
  - `well_solved`: Has good solutions (less interesting)
  - `sharing`: Sharing a solution/tool they built
  - `discussion`: General discussion/opinion
- **Solution quality tracking**: Identifies if solutions exist (none/workaround/partial/complete)
- **Key pain points extraction**: Lists up to 3 specific problems per post
- **Markdown reports**: Auto-generated business analysis with insights by community
- **Cost tracking**: Logs OpenAI API token usage and estimated costs
- **Robust error handling**: Validates API responses and handles missing fields
- **Pretty JSON output**: Well-formatted summary files with timestamps

## Installation

1. Clone this repository:
```bash
git clone https://github.com/shayonpal/check-reddit-posts.git
cd check-reddit-posts
```

2. Copy the example environment file and edit it with your credentials:
```bash
cp .env.example .env
```

3. Edit the `.env` file with your API credentials:
   - **Reddit API**: 
     1. Go to https://www.reddit.com/prefs/apps
     2. Click "Create App" or "Create Another App"
     3. Fill in the form:
        - Name: Choose any name (e.g., "Reddit Post Analyzer")
        - App type: Select **script**
        - Description: Optional
        - About URL: Leave blank
        - Redirect URI: Use `http://localhost:8080` (required but not used)
     4. Click "Create app"
     5. Your credentials will be displayed:
        - `REDDIT_CLIENT_ID`: The string under "personal use script"
        - `REDDIT_CLIENT_SECRET`: The "secret" string
   - **OpenAI API**: Get your key from https://platform.openai.com/api-keys
   - Customize the subreddits and other settings as needed

4. Ensure you have the required dependencies:
   - bash or zsh
   - curl
   - jq

## Configuration

Create a `.env` file in the project root with the following variables:

```bash
# Reddit OAuth API credentials
REDDIT_CLIENT_ID=your_client_id
REDDIT_CLIENT_SECRET=your_client_secret
REDDIT_USERNAME=your_username
REDDIT_PASSWORD=your_password
REDDIT_USER_AGENT="PostAnalyzer/0.1 by your_username"

# OpenAI API key
OPENAI_API_KEY=your_openai_api_key

# Number of posts to analyze per subreddit
NUM_POSTS=10

# Reddit post ordering logic: hot, new, top, rising, controversial
ORDER_LOGIC=top

# Timeframe for top/controversial: hour, day, week, month, year, all
TIMEFRAME=week

# Maximum number of days ago to fetch posts
MIN_DAYS_AGO=90

# Comma-separated list of subreddits
SUBREDDITS=shortcuts,automation,applescript
```

## Usage

Run the script:
```bash
./script.sh
```

The script will:
1. Authenticate with Reddit and fetch posts from configured subreddits
2. Filter posts based on your criteria
3. Send each post to OpenAI for analysis
4. Save results to a timestamped JSON file
5. Log the run details including API usage and costs

## Output

### Summary Files
- Located in `summaries/YYYY-MM-DD/` directories
- Named: `summary-YYYY-MM-DD_HH-mm-ss.json`
- Contains array of analyzed posts with:
  - Post metadata (id, title, URL, author, subreddit, timestamp, comments count)
  - Full post content
  - AI-generated analysis
  - Sentiment classification (enhanced categories)
  - Solution quality assessment
  - Business opportunity score (1-5)
  - Key pain points array
  - Top comments analyzed
  - Analysis timestamp

### Markdown Analysis Files
- Located in `summaries/YYYY-MM-DD/` directories
- Named: `analysis-YYYY-MM-DD_HH-mm-ss.md`
- Contains:
  - High-opportunity posts table (score 4-5)
  - Validated pain points by subreddit
  - Sentiment distribution statistics
  - Key insights by community (ClaudeAI, OpenAI/ChatGPT, Perplexity)
  - Cross-platform opportunities

### Log File
- `log.txt`: Tracks each run with:
  - Timestamp
  - Summary filename
  - API call counts (Reddit + OpenAI)
  - Posts analyzed
  - Ordering logic and subreddits
  - Token usage and costs

## Example Output

```json
{
  "id": "1abcdef",
  "title": "Help with automation shortcut",
  "url": "https://www.reddit.com/r/shortcuts/comments/...",
  "author": "username",
  "subreddit": "shortcuts",
  "created_utc": 1716168000,
  "description": "I'm trying to create a shortcut that...",
  "comments": 15,
  "analysis": "The user is attempting to automate...",
  "sentiment": "unsolved_problem",
  "solution_quality": "none",
  "opportunity_score": 4,
  "key_pain_points": [
    "Cannot trigger shortcuts based on app notifications",
    "No way to automate clipboard management",
    "Limited integration with third-party apps"
  ],
  "comments_analyzed": [
    {
      "author": "helper123",
      "body": "I've been looking for this too...",
      "score": 25
    }
  ],
  "analysis_timestamp": "2025-05-20T00:14:30-0400"
}
```

## Recent Updates

- **Enhanced comment analysis**: Now fetches and analyzes top 10 comments per post to identify existing solutions and community validation
- **Business opportunity scoring**: Added 1-5 scale rating for each post's business potential
- **Improved sentiment analysis**: Expanded from basic categories to business-focused classifications
- **Markdown analysis reports**: Automatically generates business insights grouped by AI community
- **Solution quality tracking**: Identifies whether solutions exist and their completeness
- **Key pain points extraction**: Extracts up to 3 specific problems from each post
- Modified output structure to organize summaries by date in `summaries/YYYY-MM-DD/` directories
- Updated to use GPT-4.1-mini model for cost efficiency

## Known Issues

- No current known issues
- This is a local-only project with no GitHub issues tracked

## Development Status

This is a personal utility script for analyzing Reddit posts to identify business opportunities and pain points across AI communities. The project is functional and being used for product research and opportunity analysis.

## License

This project is licensed under the GNU General Public License v3.0 (GPL-3.0). See [LICENSE.md](LICENSE.md) for details.

This means you are free to:
- Use, modify, and distribute this software
- Any derivative work must also be licensed under GPL-3.0
- You must include the source code when distributing
- You must state any changes made to the code

Please also respect Reddit's API terms of service and rate limits when using this tool.

## Privacy Note

Keep your `.env` file private as it contains sensitive API credentials. The `.gitignore` file is configured to exclude it from version control.
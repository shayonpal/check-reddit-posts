# Reddit Post Analyzer

A bash script that fetches posts from Reddit subreddits and uses OpenAI's GPT-4 to analyze and summarize the main problems users are trying to solve, with sentiment analysis.

## Description

This tool automates the process of:
- Fetching top posts from specified subreddits using Reddit's OAuth API
- Filtering posts by age and content criteria
- Analyzing each post with OpenAI to extract the core problem/topic
- Performing sentiment analysis (need help, sharing, ranting, etc.)
- Generating timestamped JSON summaries with detailed metadata
- Tracking API usage and costs

## Features

- **Multi-subreddit support**: Analyze posts from multiple subreddits in a single run
- **Flexible ordering**: Supports hot, new, top, rising, and controversial post ordering
- **Time-based filtering**: Filter posts by age and timeframe (hour/day/week/month/year)
- **Comprehensive analysis**: Extracts post metadata and AI-generated summaries
- **Sentiment classification**: Categorizes posts as help requests, sharing, rants, etc.
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
  - Post metadata (id, title, URL, author, subreddit, timestamp, comments)
  - Full post content
  - AI-generated analysis
  - Sentiment classification
  - Analysis timestamp

### Log File
- `log.txt`: Tracks each run with:
  - Timestamp
  - Summary filename
  - API call counts
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
  "sentiment": "need help",
  "analysis_timestamp": "2025-05-20T00:14:30-0400"
}
```

## Recent Updates

- Modified output structure to organize summaries by date in `summaries/YYYY-MM-DD/` directories
- Initial implementation with core functionality
- Support for multiple subreddits
- Configurable post ordering and timeframe
- Sentiment analysis integration
- Cost tracking for OpenAI API usage

## Known Issues

- No current known issues
- This is a local-only project with no GitHub issues tracked

## Development Status

This is a personal utility script for analyzing Reddit posts. The project is functional and being used for research into Apple Shortcuts community needs and sentiment.

## License

This project is for personal/educational use only. Please respect Reddit's API terms of service and rate limits.

## Privacy Note

Keep your `.env` file private as it contains sensitive API credentials. The `.gitignore` file is configured to exclude it from version control.
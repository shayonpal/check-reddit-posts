# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased] - 2025-06-24 15:39:14 EDT

### Added
- Initial implementation of Reddit post analyzer script
- Reddit OAuth authentication support
- OpenAI GPT-4 integration for post analysis
- Multi-subreddit support with configurable list
- Flexible post ordering options (hot, new, top, rising, controversial)
- Time-based filtering with configurable timeframe
- Sentiment analysis feature (need help, sharing, ranting, etc.)
- JSON output with comprehensive post metadata
- Cost tracking for OpenAI API usage
- Detailed logging of each run with API statistics
- Environment-based configuration via .env file
- Example summary output files from initial test runs
- Proper error handling and API response validation
- Support for filtering posts by age (MIN_DAYS_AGO parameter)

### Configuration
- Support for multiple subreddits via comma-separated list
- Configurable number of posts to analyze
- Flexible ordering logic with timeframe support
- Reddit OAuth credentials configuration
- OpenAI API key configuration

### Output
- Pretty-printed JSON summaries with timestamps
- Persistent log file tracking all runs
- Detailed post metadata including author, subreddit, comments count
- AI-generated analysis and sentiment classification
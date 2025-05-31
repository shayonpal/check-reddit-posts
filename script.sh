#!/bin/bash

#####################################################################################################
# Reddit Post Analyzer
#
# Purpose:
#   This script fetches the top N posts from one or more subreddits, analyzes each post using
#   OpenAI's GPT-4.1-mini model, and summarizes the main problem each user is trying to solve.
#
# How It Works:
#   1. The script authenticates with Reddit using OAuth and fetches posts from one or more subreddits.
#   2. You can configure subreddit(s), post ordering (hot, new, top, rising, controversial),
#      and timeframe (for top/controversial) in the .env file.
#   3. Only posts newer than a configurable number of days (MIN_DAYS_AGO) are included.
#   4. For each post, the script extracts: id, title, canonical Reddit URL, author, subreddit, created_utc,
#      selftext (description), and number of comments.
#   5. Each post is sent to OpenAI's API for summarization, and the summary is added to the output.
#   6. All results are saved in a pretty-printed JSON file with a timestamp in the local timezone.
#   7. A log file records each run, including API usage, cost, number of posts analyzed, ordering logic,
#      subreddits, and the summary file name.
#   8. The script is robust to missing fields and logs all relevant debug information.
#
# Requirements:
#   - bash (or zsh)
#   - curl
#   - jq
#
# Usage:
#   - Configure the .env file with your Reddit and OpenAI credentials and desired parameters.
#   - Run the script in a terminal.
#
# Notes:
#   - For personal projects, Reddit's rate limits are respected (default: 10 queries per minute with OAuth).
#   - The OpenAI API key is included in plaintext; keep this script private.
#   - The script is intended for educational or research purposes only.
#   - For more posts or higher frequency, consider additional Reddit API rate limit handling.
#####################################################################################################

# Load environment variables from .env file if it exists
if [ -f .env ]; then
  set -o allexport
  source .env
  set +o allexport
else
  echo "ERROR: .env file not found. Please create one with the required variables."
  exit 1
fi

# Number of posts to analyze (from .env)
NUM_POSTS=${NUM_POSTS:-3}

# OpenAI API Key (from .env)
OPENAI_API_KEY="$OPENAI_API_KEY"

# Debug: Show a masked version of the API key being used
echo "DEBUG: Using OpenAI API Key: ${OPENAI_API_KEY:0:7}********************"

if [ -z "$OPENAI_API_KEY" ]; then
  echo "ERROR: OpenAI API Key is missing."
  exit 1
fi

# Obtain Reddit OAuth access token
ACCESS_TOKEN=$(curl -s -A "$REDDIT_USER_AGENT" --user "$REDDIT_CLIENT_ID:$REDDIT_CLIENT_SECRET" \
  -d "grant_type=password&username=$REDDIT_USERNAME&password=$REDDIT_PASSWORD" \
  https://www.reddit.com/api/v1/access_token | jq -r '.access_token')

if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" == "null" ]; then
  echo "ERROR: Failed to obtain Reddit access token."
  exit 1
fi

# Supported ORDER_LOGIC values for Reddit API:
#   hot, new, top, rising, controversial
# Supported TIMEFRAME values (for ORDER_LOGIC=top or controversial):
#   hour, day, week, month, year, all
# Set these in your .env file as:
#   ORDER_LOGIC=top
#   TIMEFRAME=week
#   MIN_DAYS_AGO=7
#   SUBREDDITS=shortcuts,apple
ORDER_LOGIC=${ORDER_LOGIC:-top}
TIMEFRAME=${TIMEFRAME:-week}
MIN_DAYS_AGO=${MIN_DAYS_AGO:-0}
SUBREDDITS=${SUBREDDITS:-shortcuts}

# Prepare log file (constant name)
LOG_FILE="log.txt"
REDDIT_API_CALLS=0
OPENAI_API_CALLS=0

# Calculate the minimum created_utc timestamp
MIN_CREATED_UTC=$(date -v-"${MIN_DAYS_AGO}"d +%s)

# Prepare output file with timestamp (yyyy-MM-dd_HH-mm-ss)
TIMESTAMP=$(date -u +%Y-%m-%d_%H-%M-%S)
SUMMARY_FILE="summary-${TIMESTAMP}.json"

summaries=()
TOTAL_INPUT_TOKENS=0
TOTAL_OUTPUT_TOKENS=0

# Fetch and process posts from each subreddit
IFS=',' read -ra SUBREDDIT_LIST <<< "$SUBREDDITS"
> posts.jsonl
for SUB in "${SUBREDDIT_LIST[@]}"; do
  # Only add &t=TIMEFRAME for supported orderings
  if [[ "$ORDER_LOGIC" == "top" || "$ORDER_LOGIC" == "controversial" ]]; then
    URL="https://oauth.reddit.com/r/${SUB}/${ORDER_LOGIC}?limit=${NUM_POSTS}&t=${TIMEFRAME}"
  else
    URL="https://oauth.reddit.com/r/${SUB}/${ORDER_LOGIC}?limit=${NUM_POSTS}"
  fi
  curl -s -A "$REDDIT_USER_AGENT" -H "Authorization: bearer $ACCESS_TOKEN" \
    "$URL" | \
    jq -c --argjson min_created_utc "$MIN_CREATED_UTC" '
      .data.children[].data |
      select(.selftext != "" and .created_utc >= $min_created_utc) |
      {id: .id, title: .title, selftext: .selftext, permalink: .permalink, author: .author, subreddit: .subreddit, created_utc: .created_utc, num_comments: .num_comments}
    ' >> posts.jsonl
  REDDIT_API_CALLS=$((REDDIT_API_CALLS+1))
done

# Process each post
i=1
total=$(cat posts.jsonl | wc -l)
while read -r post; do
  post_id=$(echo "$post" | jq -r '.id // ""')
  title=$(echo "$post" | jq -r '.title // ""')
  description=$(echo "$post" | jq -r '.selftext // ""')
  permalink=$(echo "$post" | jq -r '.permalink // ""')
  url="https://www.reddit.com$permalink"
  author=$(echo "$post" | jq -r '.author // ""')
  subreddit=$(echo "$post" | jq -r '.subreddit // ""')
  created_utc=$(echo "$post" | jq -r '.created_utc // 0')
  comments=$(echo "$post" | jq -r '.num_comments // 0')

  # Build the prompt for OpenAI: ask for summary and structured sentiment analysis
  prompt_text="""
Summarize the main problem the user is trying to solve in this Reddit post about Apple Shortcuts, and perform a sentiment analysis. 

Return your response as a JSON object with two fields:
- analysis: a concise summary of the main problem or topic in the post
- sentiment: one of the following values:
    - 'need help' (if the OP is looking for a solution or asking a question)
    - 'sharing' (if the OP is just sharing information, a tip, or a shortcut)
    - 'ranting' (if the OP is venting or complaining)
    - or another appropriate label if none of the above fit

Here is the Reddit post:
Title: $title

Body: $description
"""
  prompt_json=$(jq -Rn --arg p "$prompt_text" '$p')

  echo "Analyzing post $i/$total: $title"
  echo "URL: $url"

  # Send to OpenAI and capture HTTP status code and response
  http_response=$(mktemp)
  http_code=$(curl -s -w "%{http_code}" -o "$http_response" https://api.openai.com/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -d @- <<EOF
{
  "model": "gpt-4.1-mini",
  "messages": [
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": $prompt_json}
  ]
}
EOF
  )
  OPENAI_API_CALLS=$((OPENAI_API_CALLS+1))

  echo "DEBUG: OpenAI HTTP status code: $http_code"
  cat "$http_response" | jq

  if [[ "$http_code" -ne 200 ]]; then
    echo "ERROR: OpenAI API call failed with status $http_code."
    cat "$http_response"
    rm "$http_response"
    exit 1
  fi

  # Parse the OpenAI response for structured JSON
  openai_content=$(cat "$http_response" | jq -r '.choices[0].message.content // ""')
  analysis=$(echo "$openai_content" | jq -r '.analysis // empty' 2>/dev/null)
  sentiment=$(echo "$openai_content" | jq -r '.sentiment // empty' 2>/dev/null)
  # Fallback: if not valid JSON, treat the whole response as analysis
  if [[ -z "$analysis" || -z "$sentiment" ]]; then
    analysis="$openai_content"
    sentiment=""
  fi
  analysis_timestamp=$(date +%Y-%m-%dT%H:%M:%S%z)
  echo -e "Summary: $analysis\nSentiment: $sentiment\n"
  i=$((i+1))

  # Extract token usage from OpenAI response
  input_tokens=$(cat "$http_response" | jq -r '.usage.prompt_tokens // 0')
  output_tokens=$(cat "$http_response" | jq -r '.usage.completion_tokens // 0')
  TOTAL_INPUT_TOKENS=$((TOTAL_INPUT_TOKENS + input_tokens))
  TOTAL_OUTPUT_TOKENS=$((TOTAL_OUTPUT_TOKENS + output_tokens))

  # Build JSON object for this post (all fields as strings, convert to numbers in jq)
  summary_obj=$(jq -n \
    --arg id "$post_id" \
    --arg title "$title" \
    --arg url "$url" \
    --arg author "$author" \
    --arg subreddit "$subreddit" \
    --arg created_utc "$created_utc" \
    --arg description "$description" \
    --arg comments "$comments" \
    --arg analysis "$analysis" \
    --arg sentiment "$sentiment" \
    --arg analysis_timestamp "$analysis_timestamp" \
    '{id: $id, title: $title, url: $url, author: $author, subreddit: $subreddit, created_utc: ($created_utc|tonumber), description: $description, comments: ($comments|tonumber), analysis: $analysis, sentiment: $sentiment, analysis_timestamp: $analysis_timestamp}'
  )
  summaries+=("$summary_obj")
  rm "$http_response"
done < posts.jsonl

# Calculate OpenAI API cost
INPUT_COST=$(awk "BEGIN {printf \"%.4f\", $TOTAL_INPUT_TOKENS * 0.40 / 1000000}")
OUTPUT_COST=$(awk "BEGIN {printf \"%.4f\", $TOTAL_OUTPUT_TOKENS * 1.60 / 1000000}")
TOTAL_COST=$(awk "BEGIN {printf \"%.4f\", $INPUT_COST + $OUTPUT_COST}")

# Write all summaries to the output file as a pretty-printed JSON array
printf "%s\n" "${summaries[@]}" | jq -s '.' > "$SUMMARY_FILE"
echo "Wrote summaries to $SUMMARY_FILE"

# At the end, append log entry to log.txt
{
  echo "---"
  echo "Run timestamp: $TIMESTAMP"
  echo "Summary file: $SUMMARY_FILE"
  echo "Reddit API calls: $REDDIT_API_CALLS"
  echo "OpenAI API calls: $OPENAI_API_CALLS"
  echo "Posts analyzed: $total"
  echo "Ordering logic: $ORDER_LOGIC"
  echo "Subreddits: $SUBREDDITS"
  echo "OpenAI input tokens: $TOTAL_INPUT_TOKENS"
  echo "OpenAI output tokens: $TOTAL_OUTPUT_TOKENS"
  echo "OpenAI input cost: $INPUT_COST USD"
  echo "OpenAI output cost: $OUTPUT_COST USD"
  echo "OpenAI total cost: $TOTAL_COST USD"
} >> "$LOG_FILE"
echo "Appended log entry to $LOG_FILE"
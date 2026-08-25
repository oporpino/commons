#!/usr/bin/env bash

# Claude Code Statusline Script
# Displays: Model | Session % | Week % | Opus % | Reset at

# Read JSON from stdin
input=$(cat)

# Extract model name using jq
model=$(echo "$input" | jq -r '.model.display_name // "Claude"')

# Get usage data from /status command
status_output=$(claude /status 2>&1)

# Extract percentages from the status output
# The output format is like: "Session: 21% used" or "All models: 6% used" or "Opus: 0% used"
session_pct=$(echo "$status_output" | grep -i "session" | grep -o "[0-9]\+%" | grep -o "[0-9]\+")
weekly_pct=$(echo "$status_output" | grep -i "all models" | grep -o "[0-9]\+%" | grep -o "[0-9]\+")
opus_pct=$(echo "$status_output" | grep -i "opus" | grep -o "[0-9]\+%" | grep -o "[0-9]\+")

# Set defaults if not found
session_pct=${session_pct:-0}
weekly_pct=${weekly_pct:-0}
opus_pct=${opus_pct:-0}

# Extract reset time from "Resets at..." line
reset_at=$(echo "$status_output" | grep -i "resets" | sed 's/.*Resets at //' | sed 's/ (.*//' | head -1)
reset_at=${reset_at:-"N/A"}

# Build statusline
printf "${model} | "
printf "Session: ${session_pct}%% | "
printf "Week: ${weekly_pct}%% | "
printf "Opus: ${opus_pct}%% | "
printf "Reset: ${reset_at}"
printf "\n"

#!/usr/bin/env bash
# Claude Code status line: git branch + model + 1M token price + session tokens + costs in BRL.
#
# Data flows in one direction, each stage depending only on the ones above it:
#   read_input -> exchange_rate -> model_attrs -> session_state -> period_totals -> render
#
# Every displayed value is computed exactly once. Overage cost is the cost accrued after
# the 5h rate limit first reached 100%; its baseline is snapshotted at that crossing and
# is JSON `null` (never 0) until then, so "not crossed yet" and "crossed at zero cost"
# never get confused.

set -o pipefail

SESSIONS_DIR="$HOME/.claude/cost-sessions"
RATE_CACHE_DIR="/tmp/usd_brl_rates"
RATE_CACHE_TTL=3600
RATE_FALLBACK=5.00

# ── ANSI colors ──────────────────────────────────────────────────────────────
readonly C_RESET='\033[0m'
readonly C_GRAY='\033[0;90m'
readonly C_WHITE='\033[0;37m'
readonly C_RED='\033[0;31m'
readonly C_GREEN='\033[0;32m'
readonly C_YELLOW='\033[0;33m'
readonly C_CYAN='\033[0;36m'
readonly C_BRANCH='\033[0;33m'
readonly C_ORANGE='\033[38;5;130m'
readonly C_TOKENS_LABEL='\033[38;5;22m'
readonly C_DAY_LABEL='\033[38;5;29m'
readonly C_DAY_VALUE='\033[38;5;42m'
readonly C_WEEK_LABEL='\033[38;5;23m'
readonly C_WEEK_VALUE='\033[38;5;30m'
readonly C_MONTH_LABEL='\033[38;5;61m'
readonly C_MONTH_VALUE='\033[38;5;99m'

# ── Number formatting (single source for each format) ─────────────────────────
# Compact token count: 1.2M / 34k / 512. `mode` picks k rounding to match legacy output:
#   "session" -> one decimal for k (12.3k); "total" -> integer k (34k).
fmt_tokens() {
  awk -v t="$1" -v mode="${2:-total}" 'BEGIN {
    if (t >= 1000000)      printf "%.1fM", t / 1000000
    else if (t >= 1000)    printf (mode == "session") ? "%.1fk" : "%.0fk", t / 1000
    else                   printf "%d", t
  }'
}

# BRL amount as a decimal string with comma separator, given USD and precision.
brl_str() {
  awk -v usd="$1" -v rate="$2" -v prec="${3:-2}" \
    'BEGIN { printf "%.*f", prec, usd * rate }' | tr '.' ','
}

# BRL amount rounded to whole reais (integer), given USD.
brl_int() {
  awk -v usd="$1" -v rate="$2" 'BEGIN { printf "%.0f", usd * rate }'
}

# ── Stage 1: read the stdin JSON once into in_* variables ─────────────────────
read_input() {
  local json; json=$(cat)
  in_cwd=$(jq -r '.cwd // empty'                                  <<<"$json")
  in_session_id=$(jq -r '.session_id // empty'                    <<<"$json")
  in_model_id=$(jq -r '.model.id // empty'                        <<<"$json" | sed 's/\[1m\]//g')
  in_model_name=$(jq -r '.model.display_name // empty'            <<<"$json")
  in_input_tokens=$(jq -r '.context_window.total_input_tokens // 0'  <<<"$json")
  in_output_tokens=$(jq -r '.context_window.total_output_tokens // 0' <<<"$json")
  in_cost_usd=$(jq -r '.cost.total_cost_usd // 0'                 <<<"$json")
  in_ctx_used_pct=$(jq -r '.context_window.used_percentage // empty' <<<"$json")
  in_ctx_size=$(jq -r '.context_window.context_window_size // 200000' <<<"$json")
  in_lines_added=$(jq -r '.cost.total_lines_added // 0'          <<<"$json")
  in_lines_removed=$(jq -r '.cost.total_lines_removed // 0'      <<<"$json")
  in_rl_5h=$(jq -r '.rate_limits.five_hour.used_percentage // empty'   <<<"$json")
  in_rl_7d=$(jq -r '.rate_limits.seven_day.used_percentage // empty'   <<<"$json")

  ctx_tokens=$(( in_input_tokens + in_output_tokens ))
  rl_5h_pct=$(awk -v p="${in_rl_5h:-0}" 'BEGIN { printf "%d", p }')
}

# ── Stage 2: USD -> BRL exchange rate (per-date cache, single external call) ───
rate_for_date() {
  local d="$1" cache="$RATE_CACHE_DIR/$1.cache" rate
  if [[ -f "$cache" ]]; then
    local age=$(( $(date +%s) - $(stat -f %m "$cache" 2>/dev/null || echo 0) ))
    if (( age < RATE_CACHE_TTL )); then cat "$cache"; return; fi
  fi
  rate=$(curl -sf "https://api.frankfurter.dev/v1/${d}?from=USD&to=BRL" 2>/dev/null \
    | jq -r '.rates.BRL // empty' 2>/dev/null)
  if [[ -n "$rate" ]]; then echo "$rate" > "$cache"; echo "$rate"; fi
}

exchange_rate() {
  mkdir -p "$RATE_CACHE_DIR"
  usd_brl=$(rate_for_date "latest")
  if [[ -z "$usd_brl" ]]; then
    usd_brl=$RATE_FALLBACK
    rate_is_fallback=true
  else
    rate_is_fallback=false
  fi
}

# ── Stage 3: model attributes from a single table ─────────────────────────────
# Sets: model_short, model_color, price_1m_input_usd, price_1m_output_usd.
model_attrs() {
  local color short price
  case "$in_model_id" in
    *claude-fable-5*)    color="\033[1;35m";    short="F5";   price="10.00/50.00" ;;
    *claude-mythos-5*)   color="\033[1;35m";    short="M5";   price="10.00/50.00" ;;
    *claude-opus-4-8*)   color="$C_RED";        short="O4.8"; price="5.00/25.00" ;;
    *claude-opus-4-7*)   color="$C_RED";        short="O4.7"; price="5.00/25.00" ;;
    *claude-opus-4-6*)   color="$C_RED";        short="O4.6"; price="5.00/25.00" ;;
    *claude-opus-4-5*)   color="$C_RED";        short="O4.5"; price="5.00/25.00" ;;
    *claude-opus-4*)     color="$C_RED";        short="O4";   price="15.00/75.00" ;;
    *claude-opus-3*)     color="$C_RED";        short="O3";   price="15.00/75.00" ;;
    *claude-sonnet-4-6*) color="\033[38;5;99m"; short="S4.6"; price="3.00/15.00" ;;
    *claude-sonnet-4-5*) color="\033[38;5;99m"; short="S4.5"; price="3.00/15.00" ;;
    *claude-sonnet-4*)   color="\033[38;5;99m"; short="S4";   price="3.00/15.00" ;;
    *claude-sonnet-3-7*) color="\033[0;95m";    short="S3.7"; price="3.00/15.00" ;;
    *claude-sonnet-3-5*) color="\033[0;95m";    short="S3.5"; price="3.00/15.00" ;;
    *claude-sonnet-3*)   color="\033[0;95m";    short="S3";   price="3.00/15.00" ;;
    *claude-haiku-4-5*)  color="$C_CYAN";       short="H4.5"; price="1.00/5.00" ;;
    *claude-haiku-4*)    color="$C_CYAN";       short="H4";   price="0.25/1.25" ;;
    *claude-haiku-3-5*)  color="$C_CYAN";       short="H3.5"; price="0.80/4.00" ;;
    *claude-haiku-3*)    color="$C_CYAN";       short="H3";   price="0.25/1.25" ;;
    *)                   color="\033[0;35m";    short="${in_model_name:-$in_model_id}"; price="0.00/0.00" ;;
  esac
  model_color="$color"
  model_short="$short"
  IFS='/' read -r price_1m_input_usd price_1m_output_usd <<<"$price"
}

# ── Stage 4: per-session state (compact detection + overage snapshot) ─────────
# Reads/writes $SESSIONS_DIR/<id>.json. Sets:
#   session_cost_usd       cost since the session baseline (>= 0)
#   session_tokens         accumulated tokens across compacts + current context
#   overage_baseline_usd   cost snapshot at first rl_5h==100% crossing, or "" if not crossed
session_state() {
  session_tokens=$ctx_tokens
  overage_baseline_usd=""
  session_cost_usd=$in_cost_usd
  [[ -z "$in_session_id" ]] && return

  mkdir -p "$SESSIONS_DIR"
  local file="$SESSIONS_DIR/$in_session_id.json"
  local today; today=$(date +%Y-%m-%d)
  local baseline session_date peak accumulated

  if [[ -f "$file" ]]; then
    baseline=$(jq -r '.baseline_usd // 0'           "$file" 2>/dev/null)
    session_date=$(jq -r '.date // empty'           "$file" 2>/dev/null)
    peak=$(jq -r '.peak_tokens // 0'                "$file" 2>/dev/null)
    accumulated=$(jq -r '.accumulated_tokens // 0'  "$file" 2>/dev/null)
    # a stored 0 baseline means "unset" (legacy bug); treat only >0 as a real snapshot
    overage_baseline_usd=$(jq -r 'if (.overage_baseline_usd // 0) > 0 then .overage_baseline_usd else empty end' "$file" 2>/dev/null)
    session_date="${session_date:-$today}"
    # compact detected when current context dropped below the recorded peak
    if (( ctx_tokens < peak )); then
      accumulated=$(( accumulated + peak ))
      peak=$ctx_tokens
    elif (( ctx_tokens > peak )); then
      peak=$ctx_tokens
    fi
  else
    baseline=$in_cost_usd
    session_date=$today
    peak=$ctx_tokens
    accumulated=0
  fi

  # snapshot the overage baseline once, at the first 5h==100% crossing
  if [[ -z "$overage_baseline_usd" ]] && (( rl_5h_pct >= 100 )); then
    overage_baseline_usd=$in_cost_usd
  fi

  session_cost_usd=$(awk -v c="$in_cost_usd" -v b="$baseline" \
    'BEGIN { v = c - b; if (v < 0) v = 0; printf "%.10f", v }')
  session_tokens=$(( accumulated + ctx_tokens ))

  local baseline_safe rate_safe overage_json
  baseline_safe=$(awk -v b="$baseline" 'BEGIN { printf "%.10f", b + 0 }')
  rate_safe=$(awk -v r="$usd_brl" 'BEGIN { printf "%.6f", r + 0 }')
  if [[ -n "$overage_baseline_usd" ]]; then
    overage_json=$(awk -v o="$overage_baseline_usd" 'BEGIN { printf "%.10f", o + 0 }')
  else
    overage_json="null"
  fi

  printf '{"session_id":"%s","model":"%s","cost_usd":%s,"baseline_usd":%s,"rate_brl":%s,"date":"%s","tokens":%s,"peak_tokens":%s,"accumulated_tokens":%s,"overage_baseline_usd":%s}\n' \
    "$in_session_id" "$in_model_id" "$session_cost_usd" "$baseline_safe" "$rate_safe" \
    "$session_date" "$session_tokens" "$peak" "$accumulated" "$overage_json" > "$file"
}

# Backfill rate_brl on legacy session files that predate it, preserving all fields.
backfill_rates() {
  [[ -d "$SESSIONS_DIR" ]] || return
  local f
  for f in "$SESSIONS_DIR"/*.json; do
    [[ -f "$f" ]] || continue
    if ! jq empty "$f" 2>/dev/null; then
      sed -i '' 's/"baseline_usd":,/"baseline_usd":0,/' "$f" 2>/dev/null \
        || sed -i 's/"baseline_usd":,/"baseline_usd":0,/' "$f" 2>/dev/null
    fi
    [[ -n "$(jq -r '.rate_brl // empty' "$f" 2>/dev/null)" ]] && continue
    local d; d=$(jq -r '.date' "$f" 2>/dev/null)
    local hist; hist=$(rate_for_date "$d")
    [[ -z "$hist" ]] && continue
    local tmp; tmp=$(mktemp)
    jq --argjson rate "$(awk -v r="$hist" 'BEGIN { printf "%.6f", r + 0 }')" \
      '.rate_brl = $rate' "$f" > "$tmp" 2>/dev/null && mv "$tmp" "$f" || rm -f "$tmp"
  done
}

# ── Stage 5: day/week/month totals across all session files ───────────────────
# Cost per period excludes overage (cost above the 5h threshold) so totals reflect
# plan usage, not overage. Sets total_<period>_brl and total_<period>_tokens for
# each of day, week, month. All three share sum_period, differing only in the
# jq `select` predicate that scopes which session files count.

period_files=()

# Sum non-overage cost (USD) and tokens over the files matching a jq select predicate.
# Echoes "<usd> <tokens>"; the caller splits. `predicate` runs inside `select(...)`.
sum_period() {
  local predicate="$1" usd tokens
  usd=$(jq -s "[.[] | select($predicate) | ((.cost_usd // 0) - (.overage_baseline_usd // 0)) | if . < 0 then 0 else . end] | add // 0" \
    "${period_files[@]}" 2>/dev/null || echo 0)
  tokens=$(jq -s "[.[] | select($predicate) | .tokens // 0] | add // 0" \
    "${period_files[@]}" 2>/dev/null || echo 0)
  echo "$usd $tokens"
}

period_totals() {
  local today current_month current_week
  today=$(date +%Y-%m-%d)
  current_month=$(date +%Y-%m)
  current_week=$(date -v-"$(date +%u)"d +%Y-%m-%d 2>/dev/null \
    || date -d "$(date +%Y-%m-%d) -$(date +%u) days" +%Y-%m-%d 2>/dev/null \
    || date +%Y-%m-%d)

  total_day_brl=0;   total_day_tokens=0
  total_week_brl=0;  total_week_tokens=0
  total_month_brl=0; total_month_tokens=0
  [[ -d "$SESSIONS_DIR" ]] || return

  shopt -s nullglob
  period_files=("$SESSIONS_DIR"/*.json)
  (( ${#period_files[@]} > 0 )) || return

  local usd tokens
  read -r usd tokens < <(sum_period ".date == \"$today\"")
  total_day_brl=$(brl_int "$usd" "$usd_brl");   total_day_tokens=$tokens
  read -r usd tokens < <(sum_period ".date >= \"$current_week\"")
  total_week_brl=$(brl_int "$usd" "$usd_brl");  total_week_tokens=$tokens
  read -r usd tokens < <(sum_period "(.date | startswith(\"$current_month\"))")
  total_month_brl=$(brl_int "$usd" "$usd_brl"); total_month_tokens=$tokens
}

# ── Stage 6: derive display values, then render ───────────────────────────────
render() {
  local price_1m_output_brl tokens_fmt rate_fmt ctx_pct ctx_color
  local cost_per_1k_brl session_cost_label lines_seg rl_seg branch_seg
  local day_tokens_fmt week_tokens_fmt month_tokens_fmt

  price_1m_output_brl=$(brl_int "$price_1m_output_usd" "$usd_brl")
  tokens_fmt=$(fmt_tokens "$ctx_tokens" session)
  rate_fmt=$(brl_str "$usd_brl" 1 2)
  day_tokens_fmt=$(fmt_tokens "${total_day_tokens:-0}")
  week_tokens_fmt=$(fmt_tokens "${total_week_tokens:-0}")
  month_tokens_fmt=$(fmt_tokens "${total_month_tokens:-0}")

  # context %: prefer the harness value, else derive from input tokens vs window size
  if [[ -n "$in_ctx_used_pct" ]]; then
    ctx_pct=$(awk -v p="$in_ctx_used_pct" 'BEGIN { printf "%.0f", p }')
  else
    ctx_pct=$(awk -v t="$in_input_tokens" -v s="$in_ctx_size" \
      'BEGIN { if (s > 0) printf "%.0f", t / s * 100; else print 0 }')
  fi
  ctx_color="$C_GREEN"
  if   (( ctx_pct >= 80 )); then ctx_color="$C_RED"
  elif (( ctx_pct >= 50 )); then ctx_color="$C_YELLOW"
  fi

  # cost per 1k tokens over the whole session
  cost_per_1k_brl=$(awk -v c="$in_cost_usd" -v t="$session_tokens" -v r="$usd_brl" \
    'BEGIN { if (t > 0) printf "%.3f", c / t * 1000 * r; else print "0.000" }' | tr '.' ',')

  # session cost label = overage cost (cost accrued past the 5h==100% threshold)
  if (( rl_5h_pct >= 100 )) && [[ -n "$overage_baseline_usd" ]]; then
    local overage_usd
    overage_usd=$(awk -v c="$in_cost_usd" -v o="$overage_baseline_usd" \
      'BEGIN { v = c - o; if (v < 0) v = 0; printf "%.10f", v }')
    session_cost_label="R\$$(brl_str "$overage_usd" "$usd_brl" 2)"
  else
    session_cost_label="no cost"
  fi

  lines_seg=""
  if (( in_lines_added > 0 || in_lines_removed > 0 )); then
    lines_seg=" ${C_GREEN}+${in_lines_added}${C_GRAY}/${C_RED}-${in_lines_removed}${C_RESET}"
  fi

  rl_seg=""
  if [[ -n "$in_rl_5h" ]]; then
    local rl5 rl7
    rl5=$(awk -v p="$in_rl_5h" 'BEGIN { printf "%.0f", p }')
    rl_seg=" | ${C_GRAY}5h${C_WHITE}${rl5}%%${C_RESET}"
    if [[ -n "$in_rl_7d" ]]; then
      rl7=$(awk -v p="$in_rl_7d" 'BEGIN { printf "%.0f", p }')
      rl_seg="${rl_seg} ${C_GRAY}7d${C_WHITE}${rl7}%%${C_RESET}"
    fi
  fi

  branch_seg=""
  [[ -n "$git_branch" ]] && branch_seg="${C_BRANCH}${git_branch}${C_RESET} "

  printf "${branch_seg}[ ${model_color}%s${C_RESET} ${C_GRAY}R\$${C_RESET}%s${C_GRAY}/1M${C_RESET} | ${C_TOKENS_LABEL}T${C_CYAN}%s${C_RESET} ${ctx_color}%s%%${C_RESET} ${C_ORANGE}%s${C_RESET} ${C_GRAY}R\$${C_WHITE}%s${C_GRAY}/1k${C_RESET}${lines_seg}${rl_seg} | ${C_GRAY}USD${C_WHITE}%s${C_RESET} | ${C_GRAY}D${C_DAY_LABEL}R\$${C_DAY_VALUE}%s${C_GRAY}/%s${C_RESET} ${C_GRAY}S${C_WEEK_LABEL}R\$${C_WEEK_VALUE}%s${C_GRAY}/%s${C_RESET} ${C_GRAY}M${C_MONTH_LABEL}R\$${C_MONTH_VALUE}%s${C_GRAY}/%s${C_RESET} ]" \
    "$model_short" "$price_1m_output_brl" "$tokens_fmt" "$ctx_pct" "$session_cost_label" \
    "$cost_per_1k_brl" "$rate_fmt" "$total_day_brl" "$day_tokens_fmt" \
    "$total_week_brl" "$week_tokens_fmt" \
    "$total_month_brl" "$month_tokens_fmt"
}

# ── git branch (from the session cwd, worktree-aware) ─────────────────────────
resolve_branch() {
  git_branch=""
  [[ -n "$in_cwd" ]] || return
  git_branch=$(git -C "$in_cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
    || git -C "$in_cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
}

main() {
  read_input
  exchange_rate
  resolve_branch
  model_attrs
  session_state
  backfill_rates
  period_totals
  render
}

main

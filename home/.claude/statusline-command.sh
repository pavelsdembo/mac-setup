#!/bin/bash
# Statusline: the oh-my-zsh robbyrussell prompt shape, plus session info from
# the stdin JSON payload.
set -u

input=$(cat)

# `// empty` covers both a missing key and an explicit null, which the payload
# uses early in a session and again after /compact.
dir=$(printf '%s' "$input" | jq -r '.workspace.current_dir // empty')
model=$(printf '%s' "$input" | jq -r '.model.display_name // empty')
ctx_remaining=$(printf '%s' "$input" | jq -r '.context_window.remaining_percentage // empty')
cost=$(printf '%s' "$input" | jq -r '.cost.total_cost_usd // empty')
five_hour=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
seven_day=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# Otherwise git reports whatever directory the status line inherited.
[ -n "$dir" ] || dir=$PWD

cd "$dir" 2>/dev/null || true

git_info=""
if git --no-optional-locks rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
    || git --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  if [ -n "$branch" ]; then
    dirty=""
    [ -n "$(git --no-optional-locks status --porcelain 2>/dev/null)" ] \
      && dirty=$(printf '\033[33m ✗\033[0m')
    git_info=$(printf ' \033[1;34mgit:(\033[31m%s\033[1;34m)\033[0m%s' "$branch" "$dirty")
  fi
fi

prompt=$(printf '\033[1;32m➜\033[0m \033[36m%s\033[0m%s' "$(basename "$dir")" "$git_info")

round() { awk "BEGIN{printf \"%.0f\", $1}"; }

session=""
[ -n "$model" ] && session="$session \033[2m|\033[0m $model"
[ -n "$ctx_remaining" ] && session="$session \033[2m|\033[0m Ctx:$(round "$ctx_remaining")%"
[ -n "$cost" ] && session="$session \033[2m|\033[0m \$$(awk "BEGIN{printf \"%.2f\", $cost}")"

# rate_limits is only present for Claude.ai subscribers, and each window can be
# absent independently.
usage=""
if [ -n "$five_hour" ]; then
  usage="5h:$(round "$five_hour")%"
fi
if [ -n "$seven_day" ]; then
  # Availability rather than consumption, which is what you act on.
  remaining_week=$(round "100 - ($seven_day)")
  [ -n "$usage" ] && usage="$usage "
  usage="${usage}7d avail:${remaining_week}%"
fi
[ -n "$usage" ] && session="$session \033[2m|\033[0m $usage"

printf '%b%b\n' "$prompt" "$session"

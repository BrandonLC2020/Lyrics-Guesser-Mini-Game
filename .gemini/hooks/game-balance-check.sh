#!/usr/bin/env bash
input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')

if [[ "$file_path" == *song_picker.py ]] || [[ "$file_path" == *utils.py ]] || [[ "$file_path" == *api/v1/endpoints/game.py ]]; then
  echo '{"decision": "allow", "systemMessage": "⚖️ **Hook Insight (game-balance-check)**: You modified core game logic. Consider using the `lyrics-game-logic-tester` skill to verify masking and scoring balance."}'
else
  echo '{"decision": "allow"}'
fi
exit 0

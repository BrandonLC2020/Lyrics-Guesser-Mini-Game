#!/usr/bin/env bash
input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')

if [[ "$file_path" == backend/app/schemas/* ]]; then
  echo '{"decision": "allow", "systemMessage": "💡 **Hook Insight (api-sync-expert)**: You modified a backend schema. Don'\''t forget to update the corresponding Flutter DTOs using the `api-sync-expert` skill."}'
else
  echo '{"decision": "allow"}'
fi
exit 0

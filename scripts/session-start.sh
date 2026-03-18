#!/bin/bash

# secrets.env 파일에서 환경변수를 Claude 세션으로 주입
SECRETS_FILE="/root/.claude/secrets.env"

if [ -f "$SECRETS_FILE" ]; then
    while IFS= read -r line; do
        # 빈 줄, 주석 제외
        [[ -z "$line" || "$line" == \#* ]] && continue
        echo "export $line" >> "$CLAUDE_ENV_FILE"
    done < "$SECRETS_FILE"
fi

exit 0

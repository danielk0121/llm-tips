#!/bin/bash

# 디버그 파일 남기는 플래그
DEBUG=0

# 텔레그램 봇 정보 설정 (환경변수에서 로드)
BOT_TOKEN="${TELEGRAM_BOT_TOKEN}"
CHAT_ID="${TELEGRAM_CHAT_ID}"

# stdin에서 hook 이벤트 JSON 읽기
INPUT=$(cat)

[ "$DEBUG" = "1" ] && echo "$INPUT" > ~/.claude/hooks/debug_INPUT.json

# 응답 텍스트 추출 (jq 필요)
DEFAULT_MSG="클로드 응답 완료 (메세지 파싱 불가)"
MESSAGE=$(echo "$INPUT" | jq -r ".last_assistant_message // \"$DEFAULT_MSG\"" 2>/dev/null || echo "$DEFAULT_MSG")

# 너무 길면 자르기
SHORT_MSG=$(echo "$MESSAGE" | head -c 400)
if [ ${#MESSAGE} -gt 400 ]; then
    SHORT_MSG="${SHORT_MSG} ...중략..."
fi

[ "$DEBUG" = "1" ] && echo "$SHORT_MSG" > ~/.claude/hooks/debug_SHORT_MSG.json

# 5. jq를 활용하여 텔레그램 전송용 JSON 페이로드를 생성합니다.
JSON_PAYLOAD=$(jq -n \
    --arg chat_id "$CHAT_ID" \
    --arg text "[✴️ 클로드 작업 완료] 🖥 $(hostname)

📝 응답 요약:
$SHORT_MSG" \
    '{chat_id: $chat_id, text: $text}')

curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD" \
    > /dev/null

# 훅 스크립트 종료
exit 0

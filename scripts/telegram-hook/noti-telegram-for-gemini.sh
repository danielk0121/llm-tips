#!/bin/zsh

# 디버그 파일 남기는 플래그
DEBUG=0

# 텔레그램 봇 정보 설정
TELEGRAM_BOT_TOKEN="TODO 텔레그램 봇 토큰 입력이 필요합니다"
TELEGRAM_CHAT_ID="TODO 텔레그램 채팅방 ID 가 필요합니다"

# 1. 표준 입력을 통해 넘어온 데이터를 읽습니다.
INPUT=$(cat)

[ "$DEBUG" = "1" ] && echo "$INPUT" > ~/.gemini/hooks/debug_INPUT.json

# 2. 파이썬을 사용하여 망가진 JSON에서 prompt(질문)와 prompt_response(응답)를 모두 추출합니다.
PARSED_JSON=$(echo "$INPUT" | python3 -c '
import sys, re, json

content = sys.stdin.read()

# 응답 추출 로직 (re.DOTALL로 실제 줄바꿈 포함 매칭)
res_match = re.search(r"\"prompt_response\":\"(.*?)\"\s*,\s*\"stop_hook_active\"", content, re.DOTALL)
if not res_match:
    res_match = re.search(r"\"prompt_response\":\"(.*?)\"\s*(?:\n|\})", content, re.DOTALL)
res = res_match.group(1) if res_match else ""

# 질문 추출 로직 (가장 마지막 prompt 필드 선택)
prompts = re.findall(r"\"prompt\":\"(.*?)\"\s*,\s*\"prompt_response\"", content, re.DOTALL)
pmt = prompts[-1] if prompts else ""

# 텍스트 정제 함수: 실제 줄바꿈과 탭을 이스케이프 문자열로 변환하여 JSON 안전성 확보
def escape_for_json(text):
    if not text: return ""
    # 1. 이스케이프된 따옴표 복원
    text = text.replace("\\\"", "\"")
    # 2. 실제 줄바꿈/탭을 이스케이프 문자열로 변환
    text = text.replace("\n", "\\n").replace("\t", "\\t")
    return text

print(json.dumps({"p": escape_for_json(pmt), "r": escape_for_json(res)}))
')

[ "$DEBUG" = "1" ] && echo "$PARSED_JSON" > ~/.gemini/hooks/debug_PARSED_JSON.json

# 3. 데이터 분리 및 요약 처리
# jq -r 옵션은 이스케이프된 \n을 실제 줄바꿈으로 복원하여 변수에 담습니다.
RAW_PROMPT=$(echo "$PARSED_JSON" | jq -r '.p')
RAW_RESPONSE=$(echo "$PARSED_JSON" | jq -r '.r')

# 질문 요약 (앞 400자)
if [ ${#RAW_PROMPT} -gt 400 ]; then
    SHORT_PROMPT="${RAW_PROMPT:0:400} ...중략..."
else
    SHORT_PROMPT="$RAW_PROMPT"
fi

# 응답 요약 (앞 400자)
if [ ${#RAW_RESPONSE} -gt 400 ]; then
    SHORT_RESPONSE="${RAW_RESPONSE:0:400} ...중략..."
else
    SHORT_RESPONSE="$RAW_RESPONSE"
fi

# 4. 예외 처리
if [ -z "$SHORT_PROMPT" ]; then SHORT_PROMPT="(질문 내용 파싱 불가)"; fi
if [ -z "$SHORT_RESPONSE" ]; then SHORT_RESPONSE="(응답 내용 파싱 불가)"; fi

# 5. jq를 활용하여 텔레그램 페이로드 생성
JSON_PAYLOAD=$(jq -n \
    --arg chat_id "$TELEGRAM_CHAT_ID" \
    --arg text "[💠 제미나이 작업 완료]

❓ 질문:
$SHORT_PROMPT

📝 응답 요약:
$SHORT_RESPONSE" \
    '{chat_id: $chat_id, text: $text}')

# 6. Telegram API 호출
curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD" \
    > /dev/null

# 7. 제미나이 CLI 종료 알림
echo '{"decision": "allow"}'
exit 0

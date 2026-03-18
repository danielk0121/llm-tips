# Claude 텔레그램 알림 훅 설정 가이드

Claude 세션 종료 시 텔레그램으로 알림을 보내는 훅 설정에 대한 문서입니다.

---

## 파일 구조

```
/root/.claude/                              # Claude 글로벌 설정 디렉토리
├── settings.json                           # 훅 및 권한 설정
├── secrets.env                             # 텔레그램 봇 토큰 / 채팅 ID (Git 미포함)
├── stop-hook-git-check.sh                  # 커밋/푸시 여부 체크 훅
└── hooks/
    ├── session-start.sh                    # 세션 시작 시 환경변수 주입
    └── noti-telegram-for-claude.sh         # 텔레그램 알림 전송

/home/user/llm-tips/                        # 프로젝트 저장소
├── .gitignore                              # secrets.env 제외 설정 포함
├── docs/
│   └── claude-telegram-hook.md            # 이 문서
└── scripts/
    ├── session-start.sh                    # session-start.sh 원본 (Git 추적)
    └── telegram-hook/
        └── noti-telegram-for-claude.sh     # 텔레그램 알림 스크립트 원본
```

---

## 동작 흐름

### 1. 세션 시작 시 - 환경변수 주입

```
새 Claude 세션 시작
    └→ SessionStart 훅 실행
        └→ /root/.claude/hooks/session-start.sh
            └→ /root/.claude/secrets.env 파일 읽기
                └→ $CLAUDE_ENV_FILE 에 환경변수 기록
                    └→ 세션 전체에서 아래 변수 사용 가능
                        ├── TELEGRAM_BOT_TOKEN
                        └── TELEGRAM_CHAT_ID
```

### 2. Claude 응답 완료 시 - 텔레그램 알림

```
Claude 응답 완료 (Stop 이벤트)
    └→ Stop 훅 순서대로 실행
        ├→ stop-hook-git-check.sh
        │   └→ 미커밋/미푸시 변경사항 있으면 경고
        └→ noti-telegram-for-claude.sh
            └→ $TELEGRAM_BOT_TOKEN, $TELEGRAM_CHAT_ID 참조
                └→ 응답 내용 앞 400자 추출
                    └→ 텔레그램 API 호출하여 메시지 전송
```

---

## settings.json 구조

```json
{
    "hooks": {
        "SessionStart": [
            {
                "hooks": [
                    {
                        "type": "command",
                        "command": "/root/.claude/hooks/session-start.sh"
                    }
                ]
            }
        ],
        "Stop": [
            {
                "hooks": [
                    {
                        "type": "command",
                        "command": "~/.claude/stop-hook-git-check.sh"
                    },
                    {
                        "type": "command",
                        "command": "/root/.claude/hooks/noti-telegram-for-claude.sh"
                    }
                ]
            }
        ]
    }
}
```

---

## 환경변수 설정 방법

`/root/.claude/secrets.env` 파일을 직접 수정합니다.

```bash
TELEGRAM_BOT_TOKEN="실제_봇_토큰"
TELEGRAM_CHAT_ID="실제_채팅방_ID"
```

> `secrets.env`는 `.gitignore`에 등록되어 있어 Git에 커밋되지 않습니다.

수정 후 새 세션을 시작하면 자동으로 반영됩니다.

---

## 세션 간 공유 범위

| 항목 | 공유 여부 | 비고 |
|------|----------|------|
| `settings.json` | 영구 공유 | 파일로 저장됨 |
| `secrets.env` | 영구 공유 | 파일로 저장됨, Git 미포함 |
| 환경변수 (TELEGRAM_*) | 세션 내 공유 | SessionStart 훅이 매 세션마다 주입 |
| Claude 대화 맥락 | 공유 안됨 | 세션 종료 시 초기화 |

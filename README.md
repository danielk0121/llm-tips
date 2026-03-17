# llm-tips

이 프로젝트는 LLM(Claude, Gemini 등)을 더 효율적으로 사용하기 위한 팁, 스크립트, 그리고 설정 파일들을 모아둔 저장소입니다.

## 프로젝트 개요
- **목적**: LLM 관련 도구 및 자동화 스크립트 관리
- **주요 기술**: Shell Script (zsh/bash), Python, jq

## 주요 디렉토리 및 파일
### 📂 scripts/
LLM 서비스의 훅(Hook) 시스템이나 자동화를 위한 스크립트들이 포함되어 있습니다.

- **`noti-telegram-for-gemini.sh`**: Gemini CLI의 작업 완료 이벤트를 가로채어 텔레그램 봇으로 알림을 보내는 zsh 스크립트입니다. 질문 내용과 응답 요약을 포함합니다.
- **`noti-telegram-for-claude.sh`**: Claude Code의 작업 완료 알림을 텔레그램으로 전송하는 bash 스크립트입니다.

## 설정 및 사용법
각 스크립트를 실제 LLM 도구의 훅으로 등록하는 방법은 다음과 같습니다.
- 가이드 문서 참고 : [guide.md](scripts/telegram-hook/guide.md)

## 개발 규칙
- **스크립트 작성**: 가능한 한 이식성이 좋은 Shell 문법을 사용하며, 복잡한 파싱이 필요한 경우 Python 등 외부 도구를 활용합니다.
- **보안**: API 키나 토큰과 같은 민감한 정보는 실제 운영 시 환경 변수로 관리하거나 별도의 설정 파일로 분리하는 것을 권장합니다.

# Alook Browser Skill

[English](README.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-TW.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Português](README.pt-BR.md) | [Русский](README.ru.md)

AI 에이전트가 사용자처럼 실제 브라우저를 조작하고 기존 로그인 상태를 재사용하며 토큰을 최대한 절약합니다.

AI Control이 활성화된 Alook Browser 1.0 이상이 필요합니다.

## 설치

AI 에이전트에게 보내세요:

> https://github.com/alook-browser/skill 의 공식 Alook Browser Skill을 현재 AI Agent의 사용자 수준 Skill 디렉터리에 설치하고 폴더 이름을 `alook`으로 지정하세요. 설치 후 Skill을 사용할 수 있는지 확인하세요.

선택적 CLI 설치에는 Node.js 22.20.0 이상이 필요합니다:

```bash
npx skills add alook-browser/skill -g
```

## 사용

Agent에게 Alook으로 브라우저 작업을 수행하도록 요청하세요. 명시적 Skill 명령을 지원하는 호스트에서는 `$alook` 또는 `/alook`을 사용할 수 있습니다.

## 라이선스

Apache License 2.0. 자세한 내용은 [LICENSE](LICENSE)를 참조하세요.

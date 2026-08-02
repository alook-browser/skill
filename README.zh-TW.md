# Alook Browser Skill

[English](README.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-TW.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Português](README.pt-BR.md) | [Русский](README.ru.md)

讓 AI Agent 像使用者一樣操作真實瀏覽器、沿用現有登入狀態，並最大限度節省 token。

需要 Alook Browser 1.0 或更高版本，並啟用 AI 控制。

## 安裝

傳送給你的 AI Agent：

> 請將 https://github.com/alook-browser/skill 中的官方 Alook Browser Skill 安裝到目前 AI Agent 的使用者層級 Skill 目錄，並將目錄命名為 `alook`。安裝完成後確認 Skill 可用。

可選命令列安裝需要 Node.js 22.20.0 或更高版本：

```bash
npx skills add alook-browser/skill -g
```

## 使用

讓 Agent 使用 Alook 執行瀏覽器任務。支援明確 Skill 命令的宿主可使用 `$alook` 或 `/alook`。

## 授權條款

Apache License 2.0。詳見 [LICENSE](LICENSE)。

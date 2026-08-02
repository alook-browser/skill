# Alook Browser Skill

[English](README.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-TW.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Português](README.pt-BR.md) | [Русский](README.ru.md)

让 AI Agent 像用户一样操作真实浏览器，复用现有登录状态，并最大限度节省 token。

需要 Alook Browser 1.0 或更高版本，并启用 AI 控制。

## 安装

发送给你的 AI Agent：

> 请将 https://github.com/alook-browser/skill 中的官方 Alook Browser Skill 安装到当前 AI Agent 的用户级 Skill 目录，并将目录命名为 `alook`。安装完成后确认 Skill 可用。

可选命令行安装需要 Node.js 22.20.0 或更高版本：

```bash
npx skills add alook-browser/skill -g
```

## 使用

让 Agent 使用 Alook 执行浏览器任务。支持显式 Skill 命令的宿主可使用 `$alook` 或 `/alook`。

## 许可证

Apache License 2.0。详见 [LICENSE](LICENSE)。

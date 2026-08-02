# Alook Browser Skill

[English](README.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-TW.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Português](README.pt-BR.md) | [Русский](README.ru.md)

AI エージェントがユーザーのように実際のブラウザーを操作し、既存のログイン状態を再利用し、トークンを最大限節約します。

AI コントロールを有効にした Alook Browser 1.0 以降が必要です。

## インストール

AI エージェントに送信してください：

> https://github.com/alook-browser/skill の公式 Alook Browser Skill を、この AI Agent のユーザーレベル Skill ディレクトリ内の `alook` フォルダーにインストールしてください。現在の Agent で有効にし、`alook` が利用可能な Skill リストに表示されることを確認してください。

任意の CLI インストールには Node.js 22.20.0 以降が必要です：

```bash
npx skills add alook-browser/skill -g
```

## 使用方法

Alook を使ってブラウザー操作を行うよう Agent に依頼してください。明示的な Skill コマンドに対応するホストでは `$alook` または `/alook` を使用できます。

## ライセンス

Apache License 2.0。[LICENSE](LICENSE) を参照してください。

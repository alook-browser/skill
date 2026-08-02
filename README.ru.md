# Alook Browser Skill

[English](README.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-TW.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Português](README.pt-BR.md) | [Русский](README.ru.md)

Позволяет ИИ-агентам работать с реальным браузером как пользователь, использовать существующие авторизованные сеансы и максимально экономить токены.

Требуется Alook Browser 1.0 или новее с включённым AI Control.

## Установка

Отправьте это своему ИИ-агенту:

> Установите официальный Alook Browser Skill из https://github.com/alook-browser/skill в пользовательский каталог Skills этого AI Agent, назвав папку `alook`. После установки убедитесь, что Skill доступен.

Для необязательной установки через CLI требуется Node.js 22.20.0 или новее:

```bash
npx skills add alook-browser/skill -g
```

## Использование

Попросите агента использовать Alook для работы в браузере. На хостах с явными командами Skill используйте `$alook` или `/alook`.

## Лицензия

Apache License 2.0. См. [LICENSE](LICENSE).

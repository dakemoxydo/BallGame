# Ball

Roblox-проект из [Oks1Gen/ball](https://github.com/Oks1Gen/ball). Исходники игры, ассеты и Wally-зависимости находятся в `RojoTest/`.

## Запуск

1. Выполните `rokit install` из корня репозитория.
2. В `RojoTest/` выполните `wally install`, затем `node tools/prepare-ui.mjs`.
3. Запустите `StartRojo.bat` из корня. Сервер работает скрыто на `localhost:34872`.
4. В открытой Studio `game` подключите плагин Rojo и подтвердите синхронизацию.
5. Запустите Play. Остановить сервер этого проекта можно через `StopRojo.bat`.

`node RojoTest/tools/check.mjs` запускает форматирование в режиме проверки, Selene, Lune и Rojo build. Сборка и логи находятся в `RojoTest/.tools/`.

Документация: [docs/README.md](docs/README.md). Полное историческое описание игры и авторской сцены: [RojoTest/README.md](RojoTest/README.md).

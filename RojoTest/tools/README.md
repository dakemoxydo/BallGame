# tools

Одноразовые Studio-скрипты проекта. Здесь лежат ручные процедуры: правка сцены в
Edit-режиме, перенос геометрии из Blender и регрессионные проверки после изменений.

Папка не является частью сборки игры: скрипты `.luau` не подключаются к
`default.project.json` и не попадают в `ServerScriptService`. Они выполняются
вручную из Studio и используют `_G` для передачи данных между шагами
(см. `tools/selene.toml`).

Проверка форматирования и линтинга папки выполняется командой
`node tools/check.mjs` из `RojoTest/`: StyLua проверяет все `**/*.luau`,
Selene запускается с отдельным конфигом `tools/selene.toml`.

## Как запустить скрипт

### Studio MCP (рекомендуемый способ)

1. Открыть Studio в режиме **Edit** (не Play) и убедиться, что открыт нужный place.
2. Вызвать MCP-инструмент `execute_luau` с `datamodel_type = "Edit"` и вставить
   в поле `code` тело нужного `.luau`-файла:

   ```
   studio_id    = "<идентификатор подключённой Studio>"
   datamodel_type = "Edit"
   code         = <содержимое файла tools/<Имя>.luau без внешних скобок>
   ```

3. Инструмент возвращает значение, которое скрипт завершает через `return`.
   Ошибка `assert` приходит как текст ошибки — она означает, что предусловие
   сцены не выполнено (не та карта, объект уже существует, размеры разошлись).

Для скриптов, которым нужен Play-режим (`VerifyKickProgression`), вызывается
`execute_luau` с `datamodel_type = "Server"` во время запущенного Play.

### Command Bar

1. Studio → **View → Command Bar** (в режиме Edit).
2. Вставить тело скрипта целиком и нажать **Enter**.
3. Возвращаемое значение скрипта печатается в окне Output.

Command Bar выполняет код в текущем режиме Studio, поэтому скрипты с защитой
(см. ниже) в Play-режиме остановятся с ошибкой, а не изменят сцену.

### Подготовка данных

Некоторые скрипты ждут данные во внешних глобалах; их нужно заполнить заранее:

| Переменная | Нужна скрипту | Источник |
| --- | --- | --- |
| `_G.EggColorData`, `_G.EggColorRestore` | `ApplyDecoratedEggColors.luau` | JSON из `tools/ExportDecoratedEggs.py` + предыдущий прогон `RestoreDecoratedEggColors.py` |
| `_G.TrophyImportData` | `ImportTrophy.luau` | `assets/trophy/trophy-geometry.json` |
| `_G.NormalizedOakMesh` | `ReplaceTreesWithOak.luau` | нормализованная копия геометрии дуба |
| `_G.LobbyLayoutBaseline` | `VerifyLobbyLayoutTwoAxes.luau` | снимок исходных частей; проверка пропускается, если глобал не задан |

## Защита от запуска вне Edit

Скрипты, которые меняют сцену (создают, двигают, перекрашивают объекты), в начале
файла содержат единый guard:

```lua
-- Studio Edit only: this script mutates the scene.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "This script must run in Studio, not on a live server")
assert(not RunService:IsRunning(), "This script must run in Edit mode, not during Play")
```

`RunService:IsStudio()` истинно в Studio и ложно на опубликованном сервере,
`RunService:IsRunning()` истинно только во время Play. В Edit-режиме Studio обе
проверки проходят, поэтому guard не мешает штатной работе. В Play или в проде
скрипт падает на первой строке, не успев изменить сцену.

Скрипты с префиксом `Verify` и read-only аудит `CheckSurfaceOverlaps.luau`
guard'а не имеют: они только читают сцену, поэтому их безопасно запускать и в
Edit, и в Play (там, где это указано в таблице).

## Таблица скриптов

Колонка «Режим» — требуемый режим Studio. Колонка «Идемпотентен» отвечает на
вопрос, можно ли запустить скрипт повторно без разбора последствий.

| Скрипт | Что делает | Как запускается | Режим | Идемпотентен | Меняет сцену |
| --- | --- | --- | --- | --- | --- |
| `AddLobbyWaterfall.luau` | Добавляет бирюзовый двухступенчатый водопад с прудом, мхом, тростником, цветами и лианами на правые террасы лобби. Модель `ProgressionMap.LobbyWaterfallGarden` | Studio MCP или Command Bar, Edit | Edit | Нет: при повторе `assert` о существующей модели | Да |
| `ApplyDecoratedEggColors.luau` | Переносит вершинные цвета из одного JSON-источника на меш украшенного яйца через `EditableMesh`; помечает `PendingColorMeshUpload` | Studio MCP или Command Bar, Edit, после загрузки JSON в `_G.EggColorData` | Edit | Нет: цвета накладываются повторно | Да |
| `ApplyLobbyLayoutTwoAxes.luau` | Применяет `LobbyLayoutTwoAxes.apply` и обновляет `BallStand.apply` на `ProgressionMap` через клоны модулей (обход кэша require) | Studio MCP, Edit | Edit | Да: при `LobbyLayoutVersion = 1` `apply` возвращает текущий layout | Да |
| `CheckSurfaceOverlaps.luau` | Read-only аудит перекрывающихся открытых граней блоков и клиньев в `ProgressionMap` (допуск 0.035 студ) | Studio MCP или Command Bar, Edit | Edit | Да: только чтение | Нет |
| `ColorImportedPortals.luau` | Раскрашивает импортированные порталы `portals-v6-no-textures` по шести темам, ставит атрибут `PortalTheme`, копию сохраняет в `ServerStorage.WorldBackups.BeforePortalColoring` | Studio MCP, Edit | Edit | Нет: при повторе `assert` об уже покрашенных порталах | Да |
| `ColorSakura.luau` | Раскрашивает `sakura-split-colors`: ствол, 4 кроны и 65 лепестков; копия в `WorldBackups.BeforeSplitSakuraColoring` | Studio MCP, Edit | Edit | Нет: при повторе `assert` об уже покрашенной сакуре | Да |
| `CornerRockGarden.luau` | Добавляет моховой каменный сад в левый угол входа лобби: 8 каменных масс с мхом, 5 кустов, 30 цветов, короткие лианы | Studio MCP, Edit | Edit | Нет: при повторе `assert` о существующем `CornerRockGarden` | Да |
| `ImportTrophy.luau` | Собирает модель `ImportedTrophy` из геометрии Blender через `EditableMesh`; только локальное превью, загрузка меша в Roblox требует подтверждения | Studio MCP или Command Bar, Edit, после загрузки `_G.TrophyImportData` | Edit | Нет: при повторе `assert` о существующем трофее | Да |
| `LabelImportedBalls.luau` | Подписывает 10 импортированных мячей (`BillboardGui` + якоря `LabelAnchor`), расставляет якоря над плитками витрины | Studio MCP, Edit | Edit | Да: при `StandLabelsVersion = 1` возвращает «Already labelled» | Да |
| `PlaceBallStandAtWall.luau` | Уменьшает стойку World 1 до 2/3 и ставит к правой стене, двигает 10 мячей и связанные ценники, пересчитывает `BallStand` | Studio MCP, Edit | Edit | Да: при `WallPlacementVersion = 1` возвращает «Already applied» | Да |
| `PlaceImportedBalls.luau` | Размещает 10 импортированных мячей на плитках витрины (масштаб 2.5, разворот на 90°), прячет `DisplayStone_*` | Studio MCP, Edit | Edit | Да: при `StandPlacementVersion = 1` возвращает «Already placed» | Да |
| `PlaceTrophyBehindLanes.luau` | Увеличивает `ImportedTrophy` в 5 раз и ставит за тренировочными дорожками лицом к полю | Studio MCP, Edit | Edit | Да: при `GrassPlacementVersion = 1` возвращает «Already placed» | Да |
| `PlantStoneWalkway.luau` | Дополняет каменную дорожку лобби: 6 насаждений, 18 кустов, 30 цветов; семь плит заменяются насаждениями, остальные слегка смещаются и поворачиваются | Studio MCP, Edit | Edit | Нет: при повторе `assert` о существующих `PlantedBorders` | Да |
| `RefineNativeDecor.luau` | Уточняет форму нативного декора обоих миров: каменные гребни на `FacetedRockGarden`, клиновидные листья крон дубов, прозрачность студийной текстуры | Studio MCP, Edit | Edit | Нет: при повторе `assert` об `ShapeRefinementVersion` | Да |
| `ReplaceRemainingPalmTrees.luau` | Заменяет оставшиеся пальмы обоих миров на импортированные дубы из `ServerStorage.Assets.Environment.Oak`, оригиналы переносит в `WorldBackups.BeforeOakTreeReplacement` | Studio MCP, Edit | Edit | Нет: при повторе `assert` об `OakPalmLeftoversVersion` | Да |
| `ReplaceTreesWithOak.luau` | Заменяет все блок-деревья и пальмы обоих миров на импортированный дуб, сохраняет оригиналы в бэкап, готовит шаблон в `ServerStorage.Assets.Environment` | Studio MCP, Edit, после загрузки `_G.NormalizedOakMesh` | Edit | Нет: при повторе `assert` о существующем бэкапе | Да |
| `ReverseTrainingLaneOrder.luau` | Разворачивает порядок семи тренировочных дорожек (длинная сзади, короткая спереди), двигая модели, стартовые площадки, щиты и покрытия | Studio MCP, Edit | Edit | Да: при `TrainingLaneOrderVersion = 1` возвращает «Already reversed» | Да |
| `StoneGrassWalkway.luau` | Заменяет правую полосу лобби травяным покрытием с 33 каменными плитами; физический пол `CentralWalkway` остаётся без изменений | Studio MCP, Edit | Edit | Нет: при повторе `assert` о существующей дорожке | Да |
| `VerifyAdminIsolation.luau` | Проверяет изоляцию админ-панели на mock-состоянии: авторизация, запрет мутаций вне тест-режима, откат, сохранность оригинальных данных | Studio MCP, Edit | Edit | Да: только чтение данных | Нет: временный клон `AdminService` создаётся и удаляется |
| `VerifyAdminPetCatalog.luau` | Прогоняет каталог питомцев: гранты целых пулов, одиночные гранты, тест-вылупление, вместимость инвентаря, откат состояния | Studio MCP, Edit | Edit | Да: только чтение данных | Нет: временный клон `AdminService` создаётся и удаляется |
| `VerifyBallGameplay.luau` | Проверяет транзакции покупки и экипировки мячей, десять тиров, размеры и физику моделей, по десять промптов витрины в обоих мирах, анимацию витрины | Studio MCP, Edit | Edit | Да: только чтение | Нет |
| `VerifyBiomeLengthExpansion.luau` | Проверяет растянутую трассу: восемь биомов по 270 студ, стыки, лучи по берегам, длинные стены, финальные ворота, предел броска и совпадение дистанции | Studio MCP, Edit или Server | Edit / Server | Да: только чтение | Нет |
| `VerifyEnvironmentRefresh.luau` | Проверяет нативный арт-проход: физические полы лучом, отсутствие коллизий у декора, отсутствие внешних мешей, отсутствие вторжения в реку | Studio MCP, Edit или Server | Edit / Server | Да: только чтение | Нет |
| `VerifyKickProgression.luau` | Проверяет формулы броска: рост дистанции от Skill, вклад мяча, лимит карты, семь отскоков, совпадение траектории и награды | Studio MCP, Server Script во время Play | Play (Server) | Да: только чтение | Нет |
| `VerifyLobbyLayoutTwoAxes.luau` | Развёрнуто проверяет одобренное лобби: дорожки, яйца, витрина с промптами, щиты рейтинга, портал, полы под брусчаткой; при заданном `_G.LobbyLayoutBaseline` — все исходные части | Studio MCP, Edit или Server | Edit / Server | Да: только чтение | Нет |
| `VerifyRainbowEgg.luau` | Проверяет сто исходов Rainbow, шансы, бусты, цену, сохранность других пулов и сохранённых питомцев, четыре гидратированных меша | Studio MCP, Edit | Edit | Да: только чтение | Нет |
| `VerifyRareEgg.luau` | То же для синего яйца Rare: сто исходов, шансы, бусты, цена 5000 Crowns, сохранность других пулов, четыре гидратированных меша | Studio MCP, Edit | Edit | Да: только чтение | Нет |
| `VerifyRebirthProgression.luau` | Проверяет границы уровней для восьми счётчиков перерождений, порог уровня 80, формулу сброса, случай 999 999, запрет пропуска уровня силой мяча | Studio MCP, Edit или Server | Edit / Server | Да: только чтение | Нет |
| `VerifyShotFeedback.luau` | Проверяет скорость, FOV, длину следа, время контакта и фиксированные награды за семь отскоков в обоих мирах | Studio MCP, Edit или Play | Edit / Play | Да: только чтение | Нет |
| `VerifySkippingWorld.luau` | Сверяет текущую карту с бэкапом `BeforeSkippingGame`, проверяет семь дорожек, восемь биомов, полы броска и высоту промпта портала | Studio MCP, Edit | Edit | Да: только чтение | Нет |
| `VerifyTrainingBounces.luau` | Проверяет три и четыре контакта по дорожкам, дробный нанос, камеру в четырёх размерах экрана; камера остаётся неизменной | Studio MCP, Edit или Play | Edit / Play | Да: только чтение | Нет |
| `VerifyUncommonEgg.luau` | Проверяет сто исходов зелёного яйца, шансы, цену 500 Crowns, сохранность пула Common и сохранённых питомцев, четыре гидратированных меша | Studio MCP, Edit | Edit | Да: только чтение | Нет |
| `VerifyWorldShotProgression.luau` | Проверяет пороги обоих миров, рост дистанции, эквивалентность силы мяча, большие значения Skill, предел трассы и устойчивость к переносу и повороту карты | Studio MCP, Edit или Server | Edit / Server | Да: только чтение | Нет |

## Verify-скрипты — ручные проверки, а не автотесты

Скрипты с префиксом `Verify` — это ручные регрессионные проверки, а не автотесты:

- они не входят в `check.mjs` и не запускаются при сборке;
- они не имеют ожидаемых результатов в файлах и не сравнивают снимки;
- успех означает отсутствие `assert`-ошибки и осмысленный `return` в Output;
- они не трогают прогресс игроков, валюту и DataStore, но часть из них создаёт
  и удаляет временные объекты, поэтому запускать их лучше в отдельной сессии Studio.

Проверка `node tools/check.mjs` покрывает только статические проверки проекта
(форматирование, линт, юнит-тесты `lune`, сборку Rojo, типизацию Luau).
Ручные проверки сцены выполняются отдельно, в Studio.

## Вспомогательные файлы

Кроме `.luau` в папке лежат Python-скрипты для Blender (экспорт геометрии в
JSON и обратно), служебные `.mjs`/`.ps1` и список шаблонов Ripple:

| Файл | Назначение |
| --- | --- |
| `AddRainbowPetTemplates.py`, `AddRarePetTemplates.py` | Добавляют выбранные импортированные питомцы в реестр шаблонов Rojo |
| `ExportDecoratedEggs.py`, `ExportSakuraSplitColors.py`, `ExportSakuraNoTextures.py` | Выгружают из Blender геометрию и цвета в JSON для Studio-скриптов |
| `ExportPortals.py`, `ExportPortalsNoTextures.py`, `ExportPetPack.py`, `ExportRobloxPack.py`, `ExportTrophy.py` | Выгружают геометрию порталов, питомцев и трофея из Blender в JSON |
| `InspectPetPack.py`, `InspectPortals.py`, `InspectTrophy.py` | Печатают состав и метрики исходных наборов без изменения геометрии |
| `RestoreDecoratedEggColors.py` | Возвращает исходные цвета украшенных яиц |
| `ConnectCollectorUI.py` | Однократная миграция исходников клиента; прежняя версия сохранена в `backups/` |
| `PrepareUIPackages.py` | Заменяет строковые alias'ы Ripple на Instance-require |
| `check.mjs` | Полная локальная проверка проекта (запускается из `RojoTest/`) |
| `prepare-ui.mjs` | То же для Node-части: готовит Ripple после `wally install` |
| `rojo.ps1` | Запуск и остановка Rojo-сервера проекта (`StartRojo.bat` / `StopRojo.bat`) |
| `selene.toml` | Конфигурация Selene для папки `tools`: разрешён `_G` |
| `ripple-registry.txt` | Снимок реестра шаблонов Ripple |
| `typecheck-baseline.txt` | Известные ошибки типизации Luau, с которыми сравнивается новый прогон |
| `fetch-luau-types.mjs` | Скачивает снимок типов Roblox API для офлайн-проверки типов |

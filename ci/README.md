Обзор CI-пайплайна

В этом репозитории используется планируемый GitLab пайплайн, который
генерирует полный CI конфиг и запускает тесты для выбранных приложений и
систем.

Как это работает
- Планировщик запускает задачу `prepare` из `.gitlab-ci.yml`.
- Задача выполняет `bash ci/gen-ci.sh > .gitlab-ci.yml` и пушит результат в
  ветку `ci-generated`.
- Сгенерированный пайплайн выполняет:
  - download_test: `ci/prepare_ipfs.sh`
  - publish_download_logs: `ci/push-ipfs-db.sh`
  - test: `ci/run_one_ci.sh`
  - summary: `ci/push-results-ci.sh`

Режимы работы
- Во всех тестах используется флаг `--latest`.
- Использование `--ipfs` управляется переменной `CI_USE_IPFS` (по умолчанию
  выключено).
- Стадии IPFS-загрузки управляются переменной `CI_DOWNLOAD` (по умолчанию
  выключено).
  - Если `CI_DOWNLOAD` задана, включаются `download_test` и
    `publish_download_logs`.
  - Если `CI_DOWNLOAD` не задана, стадии IPFS пропускаются.
  - Если `CI_DOWNLOAD` включена, `CI_USE_IPFS` включается автоматически.

Переменные планировщика (GitLab UI -> CI/CD -> Schedules -> Variables)
- Пресеты:
  - `FULL_TEST`: полный прогон по IPFS на `alt:sisyphus` и `debian:bookworm`,
    включает `CI_DOWNLOAD`, `CI_USE_IPFS` и `CI_IPFS_UPDATE`, тестирует все
    приложения.
  - `GET_VERSION`: сбор версий на `alt:p11`, без IPFS-стадий, тестирует все
    приложения.
- `CI_APPS`: список приложений для теста, разделенный пробелами.
  - Пример: `CI_APPS=firefox chrome`
  - Если пусто или не задано, берутся все приложения из `epm play --short`.
  - Если задан `FULL_TEST` или `GET_VERSION`, `CI_APPS` игнорируется.
- `CI_SYSTEMS`: список docker-образов для теста, разделенный пробелами.
  - Пример: `CI_SYSTEMS=alt:sisyphus debian:bookworm`
  - Если пусто или не задано, по умолчанию `alt:sisyphus debian:bookworm`.
  - Если задан `FULL_TEST` или `GET_VERSION`, `CI_SYSTEMS` игнорируется.

Допустимые значения CI_SYSTEMS
- Любые docker-образы, например `alt:sisyphus`, `debian:bookworm`,
  `ubuntu:22.04`.
- Для `alt:*` и `debian:*` есть отдельные якоря в `ci/gen-ci.d/anchors.yml`,
  остальные используют стандартный шаблон.

Формат
- Списки разделяются только пробелами.
- Передача аргументов в `ci/gen-ci.sh` не поддерживается.

Структура генератора
- Основной скрипт: `ci/gen-ci.sh`.
- Якори и настройки систем: `ci/gen-ci.d/anchors.yml`.
  - Если для системы нет якоря, используется стандартный шаблон с минимальными
    зависимостями (`/usr/bin/wget`, `/usr/bin/file`, `/usr/bin/bash`).
  - Для семейств можно использовать якоря вида `test_<family>_<mode>`,
    например `test_alt_ipfs`, `test_debian_latest`.

Переменные IPFS
- `CI_DOWNLOAD`: включает стадии загрузки и публикации IPFS базы.
- `CI_USE_IPFS`: включает флаг `--ipfs` для `epm play`.
- `CI_IPFS_UPDATE`: включает обновление IPFS базы во время теста.

Куда попадают результаты
- `FULL_TEST`: `epm-play-ci-results/epm-results`.
- `GET_VERSION`: `epm-play-ci-results/version`.
- Любые пользовательские тесты: `epm-play-ci-results/experiments`.

Метки коммитов результатов
- `full-test` для `FULL_TEST`.
- `get-version` для `GET_VERSION`.
- `custom` для пользовательских тестов.

Переменные для копирования
```
FULL_TEST
GET_VERSION
CI_APPS
CI_SYSTEMS
CI_DOWNLOAD
CI_USE_IPFS
CI_IPFS_UPDATE
```

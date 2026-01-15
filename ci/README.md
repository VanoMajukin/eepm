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
- Стадии IPFS-загрузки управляются переменной `CI_DOWNLOAD`.
  - Если `CI_DOWNLOAD` задана, включаются `download_test` и
    `publish_download_logs`.
  - Если `CI_DOWNLOAD` не задана, стадии IPFS пропускаются.

Переменные планировщика (GitLab UI -> CI/CD -> Schedules -> Variables)
- `CI_APPS`: список приложений для теста, разделенный пробелами.
  - Пример: `CI_APPS=firefox chrome`
  - Если пусто или не задано, берутся все приложения из `epm play --short`.
- `CI_SYSTEMS`: список docker-образов для теста, разделенный пробелами.
  - Пример: `CI_SYSTEMS=alt:sisyphus debian:bookworm`
  - Если пусто или не задано, по умолчанию `alt:sisyphus debian:bookworm`.

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
- `CI_IPFS_UPDATE`: включает обновление IPFS базы во время теста.

Переменные для копирования
```
CI_APPS
CI_SYSTEMS
CI_DOWNLOAD
CI_IPFS_UPDATE
```

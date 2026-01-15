Обзор CI-пайплайна

В этом репозитории используется планируемый GitLab пайплайн, который
генерирует полный CI конфиг и запускает загрузку и тесты для выбранных
приложений и систем.

Как это работает
- Планировщик запускает задачу `scheduled_ci` из `.gitlab-ci.yml`.
- Задача выполняет `bash ci/gen-ci.sh > .gitlab-ci.yml` и пушит результат в
  ветку `ci-generated`.
- Сгенерированный пайплайн выполняет:
  - download_test: `ci/prepare_ipfs.sh`
  - publish_download_logs: `ci/push-ipfs-db.sh`
  - test: `ci/run_one_ci.sh`
  - summary: `ci/push-results-ci.sh`

Переменные планировщика (GitLab UI -> CI/CD -> Schedules -> Variables)
- `CI_APPS`: список приложений для теста, разделенный пробелами.
  - Пример: `CI_APPS=firefox chrome`
  - Если пусто или не задано, берутся все приложения из `./bin/epmp --short`.
- `CI_SYSTEMS`: список docker-образов для теста, разделенный пробелами.
  - Пример: `CI_SYSTEMS=alt:sisyphus debian:bookworm`
  - Если пусто или не задано, по умолчанию `alt:sisyphus debian:bookworm`.

Допустимые значения CI_SYSTEMS
- `alt:sisyphus`
- `debian:bookworm`

Формат
- Списки разделяются только пробелами. Запятые не использовать.
- Передача аргументов в `ci/gen-ci.sh` не поддерживается.

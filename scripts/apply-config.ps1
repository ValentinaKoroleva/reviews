<#
.SYNOPSIS
  Локальный аналог шагов "Apply configurations" и "Install Quartz plugins" из .github/workflows/ci.yml.
  Копирует конфиг и контент в submodule quartz; с -Build/-Serve ещё ставит плагины и собирает сайт.
  При изменении шагов CI меняй и этот скрипт.

.EXAMPLE
  ./scripts/apply-config.ps1

.EXAMPLE
  # Применить конфигурацию и сразу собрать сайт
  ./scripts/apply-config.ps1 -Build

.EXAMPLE
  # Применить конфигурацию и запустить локальный сервер разработки
  ./scripts/apply-config.ps1 -Serve
#>
param(
    [switch]$Build,
    [switch]$Serve
)

# Сбросить локальные изменения сабмодуля перед повторным применением конфигурации
# (иначе git может отказаться обновлять сабмодуль из-за незакоммиченных правок)
git -C quartz checkout -- .
git -C quartz clean -fd

Copy-Item quartz.config.yaml quartz -Force
Copy-Item content/* quartz/content/ -Recurse -Force
Copy-Item content/static/og-image.png quartz/quartz/static/og-image.png -Force
Copy-Item scripts/install-quartz-plugins.ts quartz -Force

Write-Output "Конфигурация применена."

if ($Build -or $Serve) {
    Push-Location quartz
    # Уже установленные плагины пропускаются, так что повторный запуск быстрый
    npx tsx install-quartz-plugins.ts
    if ($Build) {
        npx quartz build
    } else {
        npx quartz build --serve --watch --baseDir reviews
    }
    Pop-Location
} else {
    Write-Output "Дальше: cd quartz; npx tsx install-quartz-plugins.ts; npx quartz build"
}


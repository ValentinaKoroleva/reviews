<#
.SYNOPSIS
  Локальный аналог шага "Apply configurations" из .github/workflows/ci.yml.
  Нужно запускать перед "npx quartz build" в submodule quartz,
  иначе локальная сборка падает на тех же багах, что были пофикшены только для CI.

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

# Fix Quartz v5 bug: collectComponents passes undefined to allComponents when footer is disabled
(Get-Content quartz/quartz/plugins/pageTypes/dispatcher.ts -Raw) `
    -replace '(?<!if \(c\) )seen\.add\(c\)', 'if (c) seen.add(c)' |
    Set-Content quartz/quartz/plugins/pageTypes/dispatcher.ts -Encoding utf8

# Fix Explorer links: add data-basepath to <body> so links include the subpath (/reviews)
Copy-Item scripts/renderPage.tsx quartz/quartz/components/renderPage.tsx -Force

Write-Output "Конфигурация применена."

if ($Build) {
    Push-Location quartz
    npx quartz build
    Pop-Location
} elseif ($Serve) {
    Push-Location quartz
    npx quartz build --serve --watch --baseDir reviews
    Pop-Location
} else {
    Write-Output "Дальше: cd quartz; npx quartz build"
}


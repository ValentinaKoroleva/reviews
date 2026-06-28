<#
.SYNOPSIS
  Создаёт новый файл рецензии в content/<год>/ с готовым frontmatter.

.EXAMPLE
  ./scripts/new-review.ps1 -Title "Преступление и наказание - Фёдора Достоевского" -Tags "российская проза","классика"

.EXAMPLE
  # Посмотреть уже существующие теги, чтобы не плодить дубли
  ./scripts/new-review.ps1 -ListTags
#>
param(
    [string]$Title,
    [string[]]$Tags = @(),
    [string]$Date = (Get-Date).ToString("yyyy-MM-dd"),
    [string]$Updated = (Get-Date).ToString("yyyy-MM-dd"),
    [switch]$ListTags
)

$TagsFile = "scripts/tags.txt"

if ($ListTags) {
    Get-Content $TagsFile
    return
}

if (-not $Title) {
    throw "Укажи -Title"
}

$knownTags = @(Get-Content $TagsFile)
$newTags = $Tags | Where-Object { $knownTags -notcontains $_ }
if ($newTags) {
    Write-Output "Новые теги (добавлены в $TagsFile): $($newTags -join ', ')"
    Write-Output "Проверь, что это не дубль уже существующего тега (например, 'литература' / 'проза')."
    $knownTags += $newTags
    $knownTags | Sort-Object -Culture ru-RU | Set-Content -Path $TagsFile -Encoding utf8
}

$Year = $Date.Substring(0, 4)
$YearDir = "content/$Year"

if (-not (Test-Path $YearDir)) {
    New-Item -ItemType Directory -Path $YearDir | Out-Null
    Set-Content -Path "$YearDir/index.md" -Value "---`ntitle: $Year`ncreated: $Date`n---`n" -Encoding utf8
}

$existingNums = Get-ChildItem $YearDir -Filter "*.md" |
    Where-Object { $_.Name -match '^\d{2}-' } |
    ForEach-Object { [int]($_.Name.Substring(0, 2)) }

$next = if ($existingNums) { ($existingNums | Measure-Object -Maximum).Maximum + 1 } else { 1 }
$num = $next.ToString("00")

$slug = $Title -replace '[\\/:*?"<>|]', '' -replace '\s+', '-'
$fileName = "$num-$slug.md"
$filePath = Join-Path $YearDir $fileName

if (Test-Path $filePath) {
    throw "Файл уже существует: $filePath"
}

$tagsLine = if ($Tags.Count -gt 0) { "[$($Tags -join ', ')]" } else { "[]" }

$content = @"
---
title: "$Title"
date: $Date # дата окончания чтения
updated: $Updated # дата изменения рецензии
tags: $tagsLine
---
**Оценка:**  (/5)

"@

Set-Content -Path $filePath -Value $content -Encoding utf8
Write-Output "Создан файл: $filePath"


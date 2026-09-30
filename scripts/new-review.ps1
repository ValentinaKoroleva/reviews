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

# UTF-8 без BOM, LF: Set-Content -Encoding utf8 в Windows PowerShell 5.1 пишет BOM
function Write-Utf8File([string]$Path, [string]$Text) {
    $fullPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    [System.IO.File]::WriteAllText($fullPath, $Text, (New-Object System.Text.UTF8Encoding $false))
}

if ($ListTags) {
    Get-Content $TagsFile -Encoding UTF8
    return
}

if (-not $Title) {
    throw "Укажи -Title"
}

$knownTags = @(Get-Content $TagsFile -Encoding UTF8)
$newTags = $Tags | Where-Object { $knownTags -notcontains $_ }
if ($newTags) {
    Write-Output "Новые теги (добавлены в $TagsFile): $($newTags -join ', ')"
    Write-Output "Проверь, что это не дубль уже существующего тега (например, 'литература' / 'проза')."
    $knownTags += $newTags
    Write-Utf8File $TagsFile ((($knownTags | Sort-Object -Culture ru-RU) -join "`n") + "`n")
}

$Year = $Date.Substring(0, 4)
$YearDir = "content/$Year"

if (-not (Test-Path $YearDir)) {
    New-Item -ItemType Directory -Path $YearDir | Out-Null
    Write-Utf8File "$YearDir/index.md" "---`ntitle: $Year`ncreated: $Date`n---`n"
}

$existingNums = Get-ChildItem $YearDir -Filter "*.md" |
    Where-Object { $_.Name -match '^\d{2}-' } |
    ForEach-Object { [int]($_.Name.Substring(0, 2)) }

$next = if ($existingNums) { ($existingNums | Measure-Object -Maximum).Maximum + 1 } else { 1 }
$num = $next.ToString("00")

$slug = $Title -replace '[\\/:*?"<>|]', '' -replace '\s+', '-' -replace '-{2,}', '-'
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

Write-Utf8File $filePath ($content -replace "`r`n", "`n")
Write-Output "Создан файл: $filePath"


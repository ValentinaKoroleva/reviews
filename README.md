# Рецензии

Личный сайт с рецензиями на книги. Собран на [Quartz][] v5 (как git submodule) и публикуется на GitHub Pages через GitHub Actions.

[Quartz]: https://github.com/jackyzha0/quartz

## Первоначальная настройка

```bash
git clone --recursive https://github.com/ValentinaKoroleva/reviews.git
cd reviews/quartz
npm ci
```

## Создание новой рецензии

```powershell
./scripts/new-review.ps1 -Title "Книга - Автор" -Tags "тег1","тег2"
```

Скрипт сам:
- определяет год по дате и кладёт файл в `content/<год>/`
- подбирает следующий порядковый номер (01, 02, 03…)
- подставляет frontmatter с заголовком, тегами и датами

Поля даты в frontmatter:
- `date` — дата окончания чтения книги (по умолчанию сегодня, можно задать `-Date YYYY-MM-DD`)
- `updated` — дата изменения рецензии (по умолчанию сегодня, можно задать `-Updated YYYY-MM-DD`; при правке старой рецензии обновляй вручную)

Посмотреть уже существующие теги (чтобы не плодить дубли вроде "литература"/"проза"):
```powershell. 
./scripts/new-review.ps1 -ListTags
```
Новые теги, переданные через `-Tags`, автоматически добавляются в `scripts/tags.txt`.

## Локальная сборка и просмотр

Quartz-сабмодуль не содержит наш `quartz.config.yaml` и контент напрямую — их нужно применить перед сборкой. Для этого есть `scripts/apply-config.ps1`:

```powershell
./scripts/apply-config.ps1 -Build   # одна сборка в quartz/public
./scripts/apply-config.ps1 -Serve   # локальный сервер с live-reload (http://localhost:8080/reviews)
```

Без флагов скрипт просто применяет конфигурацию без сборки. Скрипт идемпотентен и каждый раз сбрасывает локальные изменения сабмодуля перед применением, так что его можно гонять сколько угодно раз.

## Деплой

Пуш в `main` запускает `.github/workflows/ci.yml`, который собирает сайт и публикует его на GitHub Pages. Нужно, чтобы в настройках репозитория (Settings → Pages) источником был выбран `GitHub Actions`.

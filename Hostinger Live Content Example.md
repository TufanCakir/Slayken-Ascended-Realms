# Hostinger Live Content Example

## Recommended folder structure

```text
public_html/
  slayken/
    manifest.json
    news_items.json
    event_events.json
    backgrounds.json
    themes.json
    assets/
      festival_new_year.png
      festival_dragon.png
      aika.usdz
      shen.usdz
      zaron.usdz
      shen_texture_original.png
```

## Example `manifest.json`

```json
{
  "resources": [
    {
      "name": "news_items",
      "version": "2025-08-14-1",
      "url": "https://your-domain.com/slayken/news_items.json"
    },
    {
      "name": "event_events",
      "version": "2025-08-14-1",
      "url": "https://your-domain.com/slayken/event_events.json"
    },
    {
      "name": "backgrounds",
      "version": "2025-08-14-1",
      "url": "https://your-domain.com/slayken/backgrounds.json"
    },
    {
      "name": "themes",
      "version": "2025-08-14-1",
      "url": "https://your-domain.com/slayken/themes.json"
    }
  ],
  "assets": [
    {
      "name": "festival_new_year.png",
      "version": "2025-08-14-1",
      "url": "https://your-domain.com/slayken/assets/festival_new_year.png"
    },
    {
      "name": "aika.usdz",
      "version": "2025-08-14-1",
      "url": "https://your-domain.com/slayken/assets/aika.usdz"
    },
    {
      "name": "shen_texture_original.png",
      "version": "2025-08-14-1",
      "url": "https://your-domain.com/slayken/assets/shen_texture_original.png"
    }
  ]
}
```

## How updates work

1. Upload the changed JSON, image, or USDZ file.
2. Increase the `version` in `manifest.json`.
3. Keep the `name` exactly equal to the filename your app expects.
4. The app downloads the new version on next launch and uses the local cache.

## Notes

- Use `https`, not `http`.
- Prefer lowercase file names without spaces.
- Large USDZ files should be compressed before upload.
- Do not change gameplay code remotely, only data and assets.

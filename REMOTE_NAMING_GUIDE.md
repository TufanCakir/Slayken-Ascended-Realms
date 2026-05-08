# Remote Naming Guide

Diese Liste beschreibt den aktuellen Stand der automatisch erkannten Remote-JSONs.

## Grundregel

Eine Remote-JSON wird im Spiel nur dann automatisch geladen, wenn:

- sie im Remote-`manifest.json` als Resource eingetragen ist
- ihr Inhalt zum erwarteten JSON-Modell passt
- ihr Dateiname zu einem unterstuetzten Muster gehoert oder eine bekannte Basisdatei ersetzt

## Login-Kampagnen

- `daily_login`
- `event_login_*`
- `*_login`
- `*_login_*`

## Giftboxen

- `gift`
- `gift_*`
- `gift_box_*`

## Skilltrees

- `skill_tree`
- `skill_tree_*`
- `character_skill_tree_*`

## Story- und Event-Kapitel

- `globe_events`
- `event_events`
- `event_skill`
- `story_chapter_*`
- `chapter_*`
- `event_chapter_*`
- `event_skill_*`
- `globe_chapter_*`
- `globe_event_*`

## Ability Cards

- `ability_cards`
- `ability_cards_*`
- `summon_cards_*`

## Character Classes

- `character_classes`
- `character_classes_*`
- `character_class_*`

## Currencies

- `currencies`
- `currencies_*`
- `currency_*`

## Maps und Backgrounds

- `maps`
- `maps_*`
- `game_map_*`
- `backgrounds`
- `backgrounds_*`
- `game_background_*`

## Intro, News, Music

- `intro_videos`
- `intro_videos_*`
- `intro_video_*`
- `news_items`
- `news_items_*`
- `news_*`
- `music`
- `music_*`
- `music_tracks_*`

## Tutorials und Effekte

- `tutorials`
- `tutorials_*`
- `tutorial_*`
- `particle_effects`
- `particle_effects_*`
- `particle_effect_*`

## Summons

- `summon_characters`
- `summon_characters_*`
- `summon_character_*`
- `summon_banners`
- `summon_banners_*`
- `summon_banner_*`

## Shop

- `shop_offers`
- `shop_offers_*`
- `shop_offer_*`
- `shop_skins`
- `shop_skins_*`
- `shop_skin_*`
- `store_crystal_packs`
- `store_crystal_packs_*`
- `crystal_pack_*`
- `shop_coop_offers`
- `shop_coop_offers_*`
- `coop_shop_offer_*`
- `coop_offer_*`

## Quests und Raids

- `quests`
- `quests_*`
- `quest_*`
- `raid_bosses`
- `raid_bosses_*`
- `raid_boss_*`
- `coop_raid_*`

## Nicht frei auto-discovered

Diese Dateien sind aktuell feste Einzeldateien oder Sonderfaelle:

- `game_player`
- `battle_player`
- `battle_resources`
- `remote_content_config`
- `manifest`
- `globe_node_chests`
- `farm_limits`
- `login_campaigns`
- `deck_config`

## Wichtig

Ein komplett freier Dateiname wie `my_random_file.json` wird nicht automatisch geladen, nur weil der Inhalt formal passt.

Empfohlener Ablauf fuer neue Inhalte:

1. passenden Dateinamen nach diesem Guide waehlen
2. JSON mit korrekter Struktur erstellen
3. Resource im Remote-`manifest.json` eintragen
4. neue Version ausliefern

# Flutter to Godot Migration

This is the first playable Godot slice of the Flutter prototype.

## What was moved

- `Daycircle` became the timed day loop in `scripts/game_state.gd`.
- Food, industry, town service, storage and citizen data were moved into Godot dictionaries and arrays.
- Core simulation was ported: workers produce resources, citizens eat food, health/happiness updates, construction progresses, and the game saves to `user://savegame.json`.
- Real-industry crafting was ported as `craft_buildings`: Firewood Camp, Workshop, Tailor, Blacksmith, Brewery, Mill, Bakery, and Stable now consume inputs and create crafted resources.
- The Flutter menu/navigation idea became tabbed Godot UI in `scripts/main.gd`.
- The Flutter radial menu idea was recreated as an animated quick navigation menu in the lower-right corner.
- Flutter image/font assets were copied under `assets/`.

## Current Controls

- `Play` / `Pause`: advances one day every 2 seconds.
- `Next Day`: advances one day manually.
- `+ Worker` / `- Worker`: assigns or removes workers from production buildings.
- `Build`: starts construction.
- `Assign Builder`: assigns an unemployed citizen to the selected construction.

## Next Porting Targets

- Port the full Town Hall / event log screen.
- Add richer citizen assignment screens and field selection for farm/orchard outputs.
- Replace temporary programmatic UI with `.tscn` scene components once the gameplay shape settles.

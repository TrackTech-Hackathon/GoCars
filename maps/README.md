# Maps Folder

This folder is for developers to create and test custom maps for GoCars.

## How to Create a Map

1. Open the Map Editor scene: `scenes/map_editor/map_editor.tscn`
2. Use the controls to paint roads and grass:
   - **Left Click**: Place road tile (if you have road cards)
   - **Right Click**: Remove road tile (returns road card)
   - **WASD/Arrow Keys**: Move camera
   - **Mouse Wheel**: Zoom in/out

3. Save your map by exporting the tilemap data

## Map Files

Store your custom map files here with descriptive names:
- `tutorial_map.json`
- `city_challenge.json`
- `racing_track.json`
etc.

## Map Format

Maps should contain:
- Grid of tiles (grass or road)
- Vehicle spawn points
- Destination points
- Initial road card count
- Initial heart count

Example:
```json
{
  "name": "Simple Road",
  "tiles": [...],
  "vehicles": [{"position": [0, 4], "destination": [11, 4]}],
  "road_cards": 10,
  "hearts": 10
}
```

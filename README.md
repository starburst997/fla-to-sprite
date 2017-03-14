# fla-to-sprite

FLA to Sprite

Convert a FLA to Spritesheet based on Scene.

TODO: Add a way to select font + select properties, for now you need to edit the source code.

TODO: Add retina x2, x3 image

Example output:

![Texture](/example/Sheet/texture.png?raw=true "Example")

```json
{
  "definitions": [
    {
      "frames": [
        {
          "originHeight": 252,
          "originWidth": 4,
          "originX": -2,
          "originY": 0,
          "width": 6,
          "height": 254,
          "x": 0,
          "y": 0
        }
      ],
      "name": "SheetVLine1"
    },
    {
      "frames": [
        {
          "originHeight": 252,
          "originWidth": 4,
          "originX": -2,
          "originY": 0,
          "width": 6,
          "height": 254,
          "x": 0,
          "y": 254
        }
      ],
      "name": "SheetVLine3"
    },
    ...
  ]
}
```
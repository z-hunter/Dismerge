components {
  id: "script"
  component: "/scripts/generator_icon.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"energy_icon\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "size {\n"
  "  x: 32.0\n"
  "  y: 32.0\n"
  "}\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/tile.atlas\"\n"
  "}\n"
  ""
  scale {
    x: 1.0
    y: 1.0
  }
}

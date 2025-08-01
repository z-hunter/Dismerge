components {
  id: "item_script"
  component: "/scripts/item_script.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"tile\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/tile.atlas\"\n"
  "}\n"
  ""
}

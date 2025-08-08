components {
  id: "token"
  component: "/scripts/token.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"token\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/assets/tile.atlas\"\n"
  "}\n"
  ""
}
embedded_components {
  id: "label"
  type: "label"
  data: "size {\n"
  "  x: 64.0\n"
  "  y: 64.0\n"
  "}\n"
  "text: \"x\"\n"
  "font: \"/builtins/fonts/default.font\"\n"
  "material: \"/builtins/fonts/label-df.material\"\n"
  ""
}

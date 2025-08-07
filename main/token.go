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
embedded_components {
  id: "generator_icon"
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
  position {
    x: 20.0
    y: -20.0
    z: 0.6
  }
  scale {
    x: 0.5
    y: 0.5
    z: 0.5
  }
}

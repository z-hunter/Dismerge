components {
  id: "ui_script"
  component: "/scripts/ui.script"
}
embedded_components {
  id: "info_label"
  type: "label"
  data: "size {\n"
  "  x: 300.0\n"
  "  y: 32.0\n"
  "}\n"
  "text: \"Label\"\n"
  "font: \"/assets/iosevka.font\"\n"
  "material: \"/builtins/fonts/label-df.material\"\n"
  ""
  position {
    x: 300.0
    y: 420.0
  }
}

package project

import zd "0d/odin"
import "0d/odin/std"

main :: proc() {
    main_container_name, diagram_names := std.parse_command_line_args ()
    palette := std.initialize_component_palette (diagram_names, components_to_include_in_project)
    std.run (&palette, main_container_name, diagram_names, start_function)
}

start_function :: proc (main_container : ^zd.Eh) {
    filename := zd.new_datum_string ("test.p")
    msg := zd.make_message("input", filename, zd.make_cause (main_container, nil) )
    main_container.handler(main_container, msg)
}


components_to_include_in_project :: proc (leaves: ^[dynamic]zd.Leaf_Template) {
    zd.append_leaf (leaves, std.string_constant ("literal"))
    zd.append_leaf (leaves, std.string_constant ("words"))
    zd.append_leaf (leaves, std.string_constant ("literal.ohm"))
    zd.append_leaf (leaves, std.string_constant ("literal.rwr"))
    zd.append_leaf (leaves, std.string_constant ("words.ohm"))
    zd.append_leaf (leaves, std.string_constant ("words.rwr"))
    zd.append_leaf (leaves, std.string_constant ("null.js"))
}




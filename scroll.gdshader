shader_type canvas_item;

uniform sampler2D water_texture;
uniform vec2 texture_size; // tamaño en píxeles de la textura
uniform vec2 direction = vec2(1.0, 0.0);
uniform float speed = 0.5;
uniform float tile_size = 16.0; // tamaño del tile en píxeles

void fragment() {
    // Calculamos cuántas veces se repite la textura dentro del tile
    float scale_uv = texture_size.x / tile_size;

    vec2 move = direction * speed * TIME;
    vec2 uv = fract(UV * scale_uv + move);

    COLOR = texture(water_texture, uv);
}

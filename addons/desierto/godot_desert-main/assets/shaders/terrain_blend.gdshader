shader_type spatial;

uniform vec2 uv_scale = vec2(1.0);
uniform sampler2D noise_texture;
uniform vec4 sand_color : source_color = vec4(0.76, 0.70, 0.50, 1.0);
uniform vec4 sand_color_dark : source_color = vec4(0.66, 0.60, 0.40, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.8;
uniform float metallic : hint_range(0.0, 1.0) = 0.1;
uniform float wave_speed = 0.1;
uniform float wave_intensity = 0.02;

varying vec3 vertex_pos;

void vertex() {
    vertex_pos = VERTEX;
    
    // Añadir movimiento ondulante sutil
    float time = TIME * wave_speed;
    float wave = sin(vertex_pos.x * 2.0 + time) * cos(vertex_pos.z * 2.0 + time) * wave_intensity;
    VERTEX.y += wave;
}

void fragment() {
    // Coordenadas UV con escala
    vec2 scaled_uv = UV * uv_scale;
    
    // Generar patrón de ruido para la textura de la arena
    vec2 noise_uv = scaled_uv + vec2(TIME * 0.05);
    float noise = texture(noise_texture, noise_uv).r;
    
    // Mezclar colores de arena basado en el ruido
    vec4 final_color = mix(sand_color_dark, sand_color, noise);
    
    // Aplicar variaciones de color basadas en la posición
    float height_variation = smoothstep(0.0, 1.0, vertex_pos.y);
    final_color = mix(final_color, sand_color_dark, height_variation * 0.3);
    
    // Asignar propiedades del material
    ALBEDO = final_color.rgb;
    ROUGHNESS = roughness + noise * 0.1;
    METALLIC = metallic;
    
    // Agregar relieve sutil
    NORMAL = normalize(vec3(
        noise * 2.0 - 1.0,
        1.0,
        noise * 2.0 - 1.0
    ));
}

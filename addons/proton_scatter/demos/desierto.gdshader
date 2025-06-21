shader_type spatial;

uniform sampler2D noise_texture;

// Colores de arena más naturales basados en la imagen
const vec4 SAND_COLOR_LIGHT = vec4(0.95, 0.87, 0.70, 1.0);  // Arena clara
const vec4 SAND_COLOR_SHADOW = vec4(0.85, 0.75, 0.55, 1.0); // Sombras suaves

// Parámetros para las ondulaciones
const float WAVE_SCALE = 2.0;           // Escala de las ondas
const float WAVE_SPEED = 0.02;          // Velocidad del movimiento
const float WAVE_HEIGHT = 0.15;         // Altura de las ondas
const vec2 GRAIN_SCALE = vec2(30.0);    // Escala de la granularidad

varying vec3 vertex_pos;

// Función para generar ondulaciones naturales
float wave_pattern(vec2 position, float time) {
    float wave1 = sin(position.x * WAVE_SCALE + position.y * 0.5 + time) * 0.5;
    float wave2 = sin(position.y * WAVE_SCALE * 0.8 + position.x * 0.7 - time * 1.2) * 0.5;
    return (wave1 + wave2) * WAVE_HEIGHT;
}

// Función para la textura granular
float grain_texture(vec2 uv, float time) {
    vec2 scaled_uv = uv * GRAIN_SCALE;
    float grain = texture(noise_texture, scaled_uv + time * 0.01).r;
    float fine_grain = texture(noise_texture, scaled_uv * 2.0 - time * 0.005).r;
    return mix(grain, fine_grain, 0.5);
}

void vertex() {
    vertex_pos = VERTEX;
    
    // Aplicar ondulaciones suaves
    float time = TIME * WAVE_SPEED;
    float wave = wave_pattern(vertex_pos.xz, time);
    VERTEX.y += wave;
    
    // Ajustar normales para iluminación correcta
    float wave_dx = wave_pattern(vertex_pos.xz + vec2(0.01, 0.0), time) - wave;
    float wave_dz = wave_pattern(vertex_pos.xz + vec2(0.0, 0.01), time) - wave;
    NORMAL = normalize(vec3(-wave_dx * 100.0, 1.0, -wave_dz * 100.0));
}

void fragment() {
    float time = TIME * WAVE_SPEED;
    
    // Generar textura granular
    float grain = grain_texture(UV, time);
    float fine_grain = grain_texture(UV * 1.5, time * 1.2);
    
    // Calcular sombreado basado en la altura y normales
    float height_factor = vertex_pos.y * 2.0;
    float normal_factor = dot(NORMAL, vec3(0.0, 1.0, 0.0));
    
    // Combinar colores
    vec4 sand_color = mix(SAND_COLOR_SHADOW, SAND_COLOR_LIGHT, 
                         normal_factor * 0.5 + 0.5 + height_factor);
    
    // Añadir variación granular
    sand_color = mix(sand_color, SAND_COLOR_SHADOW, grain * 0.2);
    sand_color = mix(sand_color, SAND_COLOR_LIGHT, fine_grain * 0.1);
    
    // Aplicar al material
    ALBEDO = sand_color.rgb;
    ROUGHNESS = 0.7 + grain * 0.3;
    METALLIC = 0.0;
    
    // Normal mapping sutil para la granularidad
    vec3 grain_normal = normalize(vec3(
        grain * 2.0 - 1.0,
        8.0,
        fine_grain * 2.0 - 1.0
    ));
    
    NORMAL = normalize(mix(NORMAL, grain_normal, 0.1));
}
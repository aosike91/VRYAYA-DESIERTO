shader_type canvas_item;

uniform vec4 color_base : source_color = vec4(1.0, 0.75, 0.3, 1.0);
uniform vec4 color_llama : source_color = vec4(1.0, 0.3, 0.1, 1.0);
uniform float velocidad : hint_range(0.1, 5.0) = 1.0;
uniform float intensidad : hint_range(0.1, 2.0) = 1.0;
uniform float distorsion : hint_range(0.1, 5.0) = 3.0;

float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);

    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(vec2 uv) {
    float valor = 0.0;
    float amplitud = 0.5;
    float frecuencia = 0.0;

    for(int i = 0; i < 5; i++) {
        valor += amplitud * noise(uv);
        uv *= 2.0;
        amplitud *= 0.5;
    }
    return valor;
}

void fragment() {
    vec2 uv = UV;
    float tiempo = TIME * velocidad;

    // Genera el efecto base del fuego
    float fuego = fbm(vec2(uv.x * distorsion, uv.y * 2.0 + tiempo));
    fuego *= (1.0 - uv.y); // Hace que el fuego se desvanezca hacia arriba

    // Añade distorsión adicional
    float distorsion_x = fbm(vec2(uv.x * 3.0, uv.y * 2.0 + tiempo * 0.5)) * 0.1;
    fuego += distorsion_x;

    // Aplica la intensidad
    fuego *= intensidad;

    // Mezcla los colores
    vec4 color_final = mix(color_llama, color_base, fuego);
    color_final.a = smoothstep(0.0, 0.5, fuego);

    COLOR = color_final;
}
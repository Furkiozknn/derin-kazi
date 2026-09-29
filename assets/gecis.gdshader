shader_type canvas_item;
// Ekran gecisleri (gunluk video gecis aileleri: sosyal/uret/sahne.js GECIS).
// p = ortme miktari (0 acik, 1 tam kapali). tur = Tema.GECIS_TURLERI sirasi.
// GL Compatibility'de calisir; ekran dokusu yalniz glitch ve zoom'da okunur.
uniform sampler2D ekran : hint_screen_texture, filter_linear, repeat_disable;
uniform int tur = 0;
uniform float p : hint_range(0.0, 1.0) = 0.0;
uniform float adim = 0.0;                 // glitch: 30 Hz'e yuvarlanmis zaman tohumu
uniform vec4 renk : source_color = vec4(1.0, 0.76, 0.1, 1.0);
uniform vec4 renk2 : source_color = vec4(0.1, 0.83, 0.9, 1.0);
uniform float oran = 1.7778;

float h(vec2 x) {
	return fract(sin(dot(x, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	if (p <= 0.001) {
		discard;
	}
	vec2 uv = UV;
	vec4 c = vec4(0.0);
	if (tur == 0) {                        // iris: daire ortaya kapanir
		float d = length((uv - 0.5) * vec2(oran, 1.0));
		float r = (1.0 - p) * 1.05;
		if (d > r) {
			c = renk;
		} else if (d > r - 0.035) {
			c = renk2;
		}
	} else if (tur == 1) {                 // glitch: yatay dilimler kayar, renge doner
		float b = floor(uv.y * 28.0);
		float r = h(vec2(b, adim));
		float kayma = (r - 0.5) * 0.32 * min(p * 3.0, 1.0);
		vec2 s = SCREEN_UV + vec2(kayma, 0.0);
		vec3 g = vec3(texture(ekran, s + vec2(0.012 * p, 0.0)).r, texture(ekran, s).g, texture(ekran, s - vec2(0.012 * p, 0.0)).b);
		c = vec4(g, 1.0);
		float k = h(vec2(b, 3.0));
		if (k < p) {
			c = (h(vec2(b, 7.0)) < 0.5) ? renk : renk2;
		}
	} else if (tur == 2) {                 // bloklar: kareler ortadan buyur
		vec2 g = vec2(12.0, 7.0);
		vec2 id = floor(uv * g);
		vec2 f = fract(uv * g);
		float yerel = clamp((p - h(id) * 0.55) / 0.45, 0.0, 1.0);
		if (yerel > 0.0 && max(abs(f.x - 0.5), abs(f.y - 0.5)) <= yerel * 0.5) {
			c = (h(id + 5.0) < 0.5) ? renk : renk2;
		}
	} else if (tur == 3) {                 // itme: egik bant soldan girer
		float x = uv.x + (uv.y - 0.5) * 0.12;
		float e = p * 1.24 - 0.06;
		if (x < e) {
			c = renk;
		} else if (x < e + 0.035) {
			c = renk2;
		}
	} else if (tur == 4) {                 // perde: egik perde, kenarinda serit
		float x = uv.x - uv.y * 0.35;
		float e = p * 1.5 - 0.35;
		if (x < e) {
			c = renk;
		} else if (x < e + 0.05) {
			c = renk2;
		}
	} else if (tur == 5 || tur == 6) {     // flas (tek vurus) ve kararma: duz renk, alfa = p
		c = vec4(renk.rgb, p);
	} else {                               // zoom: sahne buyuyerek rengin icinde erir
		vec2 s = (SCREEN_UV - 0.5) * mix(1.0, 0.55, p) + 0.5;
		c = vec4(mix(texture(ekran, s).rgb, renk.rgb, smoothstep(0.25, 1.0, p)), 1.0);
	}
	COLOR = c;
}

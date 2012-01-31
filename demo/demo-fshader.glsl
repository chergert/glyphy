uniform float u_contrast;
uniform float u_gamma;
uniform bool  u_debug;

varying vec4 v_glyph;

struct glyph_info_t {
  int glyph_layout;
  ivec2 atlas_pos;
};

glyph_info_t
glyph_info_decode (vec4 v)
{
  glyph_info_t gi;
  ivec2 gl = ivec2 (mod (v_glyph.zw, 256));
  gi.glyph_layout = gl.x * 256 + gl.y;
  gi.atlas_pos = ivec2 (v_glyph.zw) / 256;
  return gi;
}

void
main()
{
  vec2 p = v_glyph.xy;
  glyph_info_t gi = glyph_info_decode (v_glyph);

  /* isotropic antialiasing */
  vec2 dpdx = dFdx (p);
  vec2 dpdy = dFdy (p);
  float m = max (length (dpdx), length (dpdy));

  vec4 color = vec4 (0,0,0,1);

  float gsdist = glyphy_sdf (p, gi.glyph_layout GLYPHY_DEMO_EXTRA_ARGS);
  float sdist = gsdist / m * u_contrast;

  if (!u_debug) {
    if (sdist > 1)
      discard;
    color = vec4 (1,1,1,1) * smoothstep (-1, 1, sdist);
    color = pow (color, vec4 (1,1,1,1) * u_gamma);
  } else {
    // Color the inside of the glyph a light red
    color += vec4 (.5,0,0,0) * smoothstep (1, -1, sdist);

    float udist = abs (sdist);
    float gudist = abs (gsdist);
    // Color the outline red
    color += vec4 (1,0,0,0) * smoothstep (2, 0, udist);
    // Color the distance field in green
    color += vec4 (0,1,0,0) * ((1 + sin (sdist))) * sin (pow (gudist, .8) * 3.14159265358979) * .5;

    float pdist = glyphy_point_dist (p, gi.glyph_layout GLYPHY_DEMO_EXTRA_ARGS) / m;
    // Color points green
    color = mix (vec4 (0,1,0,1), color, smoothstep (2, 3, pdist));

    glyphy_arc_list_t arc_list = glyphy_arc_list (p, gi.glyph_layout GLYPHY_DEMO_EXTRA_ARGS);
    // Color the number of endpoints per cell blue
    color += vec4 (0,0,1,0) * arc_list.num_endpoints * 32./255.;
  }

  gl_FragColor = color;
}
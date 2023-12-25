fixed random(fixed2 position)
{
    return frac(sin(dot(position.xy, fixed2(12.9898,78.233))) * 43758.5453123);
}

fixed noise(fixed2 position)
{
    fixed2 i = floor(position);
    fixed2 f = frac(position);

    fixed a = random(i);
    fixed b = random(i + fixed2(1.0, 0.0));
    fixed c = random(i + fixed2(0.0, 1.0));
    fixed d = random(i + fixed2(1.0, 1.0));

    fixed2 u = f * f * (3.0 - 2.0 * f);
    return lerp(a, b, u.x)
            + (c - a) * u.y * (1.0 - u.x)
            + (d - b) * u.x * u.y;
}

fixed fbm(fixed2 position, fixed octaves)
{
    fixed v = 0.0;
    fixed a = 0.5;
    fixed2 shift = fixed2(100, 100);
    fixed2x2 rotation = fixed2x2(cos(0.5), sin(0.5), -sin(0.5), cos(0.5));

    for (int i = 0; i < octaves; ++i)
    {
        v += a * noise(position);
        position = mul(rotation, position) * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}
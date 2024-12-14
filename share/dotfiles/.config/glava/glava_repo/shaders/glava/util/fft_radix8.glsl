/* Copyright (C) 2015 Hans-Kristian Arntzen <maister@archlinux.us>
 *
 * Permission is hereby granted, free of charge,
 * to any person obtaining a copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

void FFT8_p1(inout cfloat a, inout cfloat b, inout cfloat c, inout cfloat d, inout cfloat e, inout cfloat f, inout cfloat g, inout cfloat h)
{
    butterfly_p1(a, e);
    butterfly_p1(b, f);
    butterfly_p1_dir_j(c, g);
    butterfly_p1_dir_j(d, h);

    butterfly_p1(a, c);
    butterfly_p1_dir_j(b, d);
    butterfly_p1(e, g);
    butterfly_p1(f, h);

    butterfly_p1(a, b);
    butterfly_p1(c, d);
    butterfly(e, f, TWIDDLE_1_8);
    butterfly(g, h, TWIDDLE_3_8);
}

void FFT8(inout cfloat a, inout cfloat b, inout cfloat c, inout cfloat d, inout cfloat e, inout cfloat f, inout cfloat g, inout cfloat h, uint i, uint p)
{
    uint k = i & (p - 1u);

    ctwiddle w = twiddle(k, p);
    butterfly(a, e, w);
    butterfly(b, f, w);
    butterfly(c, g, w);
    butterfly(d, h, w);

    ctwiddle w0 = twiddle(k, 2u * p);
    ctwiddle w1 = cmul_dir_j(w0);

    butterfly(a, c, w0);
    butterfly(b, d, w0);
    butterfly(e, g, w1);
    butterfly(f, h, w1);

    ctwiddle W0 = twiddle(k, 4u * p);
    ctwiddle W1 = cmul(W0, TWIDDLE_1_8);
    ctwiddle W2 = cmul_dir_j(W0);
    ctwiddle W3 = cmul_dir_j(W1);

    butterfly(a, b, W0);
    butterfly(c, d, W2);
    butterfly(e, f, W1);
    butterfly(g, h, W3);
}

void FFT8_p1_horiz(uvec2 i)
{
    uint octa_samples = gl_NumWorkGroups.x * gl_WorkGroupSize.x;
    uint offset = i.y * octa_samples * 8u;

#ifdef FFT_INPUT_TEXTURE
    cfloat a = load_texture(i);
    cfloat b = load_texture(i + uvec2(octa_samples, 0u));
    cfloat c = load_texture(i + uvec2(2u * octa_samples, 0u));
    cfloat d = load_texture(i + uvec2(3u * octa_samples, 0u));
    cfloat e = load_texture(i + uvec2(4u * octa_samples, 0u));
    cfloat f = load_texture(i + uvec2(5u * octa_samples, 0u));
    cfloat g = load_texture(i + uvec2(6u * octa_samples, 0u));
    cfloat h = load_texture(i + uvec2(7u * octa_samples, 0u));
#else
    cfloat a = load_global(offset + i.x);
    cfloat b = load_global(offset + i.x + octa_samples);
    cfloat c = load_global(offset + i.x + 2u * octa_samples);
    cfloat d = load_global(offset + i.x + 3u * octa_samples);
    cfloat e = load_global(offset + i.x + 4u * octa_samples);
    cfloat f = load_global(offset + i.x + 5u * octa_samples);
    cfloat g = load_global(offset + i.x + 6u * octa_samples);
    cfloat h = load_global(offset + i.x + 7u * octa_samples);
#endif
    FFT8_p1(a, b, c, d, e, f, g, h);

#ifndef FFT_OUTPUT_IMAGE
#if FFT_CVECTOR_SIZE == 4
    store_global(offset + 8u * i.x + 0u, cfloat(a.x, e.x, c.x, g.x));
    store_global(offset + 8u * i.x + 1u, cfloat(b.x, f.x, d.x, h.x));
    store_global(offset + 8u * i.x + 2u, cfloat(a.y, e.y, c.y, g.y));
    store_global(offset + 8u * i.x + 3u, cfloat(b.y, f.y, d.y, h.y));
    store_global(offset + 8u * i.x + 4u, cfloat(a.z, e.z, c.z, g.z));
    store_global(offset + 8u * i.x + 5u, cfloat(b.z, f.z, d.z, h.z));
    store_global(offset + 8u * i.x + 6u, cfloat(a.w, e.w, c.w, g.w));
    store_global(offset + 8u * i.x + 7u, cfloat(b.w, f.w, d.w, h.w));
#elif FFT_CVECTOR_SIZE == 2
    store_global(offset + 8u * i.x + 0u, cfloat(a.xy, e.xy));
    store_global(offset + 8u * i.x + 1u, cfloat(c.xy, g.xy));
    store_global(offset + 8u * i.x + 2u, cfloat(b.xy, f.xy));
    store_global(offset + 8u * i.x + 3u, cfloat(d.xy, h.xy));
    store_global(offset + 8u * i.x + 4u, cfloat(a.zw, e.zw));
    store_global(offset + 8u * i.x + 5u, cfloat(c.zw, g.zw));
    store_global(offset + 8u * i.x + 6u, cfloat(b.zw, f.zw));
    store_global(offset + 8u * i.x + 7u, cfloat(d.zw, h.zw));
#else
    store_global(offset + 8u * i.x + 0u, a);
    store_global(offset + 8u * i.x + 1u, e);
    store_global(offset + 8u * i.x + 2u, c);
    store_global(offset + 8u * i.x + 3u, g);
    store_global(offset + 8u * i.x + 4u, b);
    store_global(offset + 8u * i.x + 5u, f);
    store_global(offset + 8u * i.x + 6u, d);
    store_global(offset + 8u * i.x + 7u, h);
#endif
#endif
}

void FFT8_p1_vert(uvec2 i)
{
    uvec2 octa_samples = gl_NumWorkGroups.xy * gl_WorkGroupSize.xy;
    uint stride = uStride;
    uint y_stride = stride * octa_samples.y;
    uint offset = stride * i.y;

#ifdef FFT_INPUT_TEXTURE
    cfloat a = load_texture(i);
    cfloat b = load_texture(i + uvec2(0u, octa_samples.y));
    cfloat c = load_texture(i + uvec2(0u, 2u * octa_samples.y));
    cfloat d = load_texture(i + uvec2(0u, 3u * octa_samples.y));
    cfloat e = load_texture(i + uvec2(0u, 4u * octa_samples.y));
    cfloat f = load_texture(i + uvec2(0u, 5u * octa_samples.y));
    cfloat g = load_texture(i + uvec2(0u, 6u * octa_samples.y));
    cfloat h = load_texture(i + uvec2(0u, 7u * octa_samples.y));
#else
    cfloat a = load_global(offset + i.x + 0u * y_stride);
    cfloat b = load_global(offset + i.x + 1u * y_stride);
    cfloat c = load_global(offset + i.x + 2u * y_stride);
    cfloat d = load_global(offset + i.x + 3u * y_stride);
    cfloat e = load_global(offset + i.x + 4u * y_stride);
    cfloat f = load_global(offset + i.x + 5u * y_stride);
    cfloat g = load_global(offset + i.x + 6u * y_stride);
    cfloat h = load_global(offset + i.x + 7u * y_stride);
#endif

    FFT8_p1(a, b, c, d, e, f, g, h);

#ifndef FFT_OUTPUT_IMAGE
    store_global((8u * i.y + 0u) * stride + i.x, a);
    store_global((8u * i.y + 1u) * stride + i.x, e);
    store_global((8u * i.y + 2u) * stride + i.x, c);
    store_global((8u * i.y + 3u) * stride + i.x, g);
    store_global((8u * i.y + 4u) * stride + i.x, b);
    store_global((8u * i.y + 5u) * stride + i.x, f);
    store_global((8u * i.y + 6u) * stride + i.x, d);
    store_global((8u * i.y + 7u) * stride + i.x, h);
#endif
}

void FFT8_horiz(uvec2 i, uint p)
{
    uint octa_samples = gl_NumWorkGroups.x * gl_WorkGroupSize.x;
    uint offset = i.y * octa_samples * 8u;

    cfloat a = load_global(offset + i.x);
    cfloat b = load_global(offset + i.x + octa_samples);
    cfloat c = load_global(offset + i.x + 2u * octa_samples);
    cfloat d = load_global(offset + i.x + 3u * octa_samples);
    cfloat e = load_global(offset + i.x + 4u * octa_samples);
    cfloat f = load_global(offset + i.x + 5u * octa_samples);
    cfloat g = load_global(offset + i.x + 6u * octa_samples);
    cfloat h = load_global(offset + i.x + 7u * octa_samples);

    FFT8(a, b, c, d, e, f, g, h, FFT_OUTPUT_STEP * i.x, p);

    uint k = (FFT_OUTPUT_STEP * i.x) & (p - 1u);
    uint j = ((FFT_OUTPUT_STEP * i.x - k) * 8u) + k;

#ifdef FFT_OUTPUT_IMAGE
    store(ivec2(j + 0u * p, i.y), a);
    store(ivec2(j + 1u * p, i.y), e);
    store(ivec2(j + 2u * p, i.y), c);
    store(ivec2(j + 3u * p, i.y), g);
    store(ivec2(j + 4u * p, i.y), b);
    store(ivec2(j + 5u * p, i.y), f);
    store(ivec2(j + 6u * p, i.y), d);
    store(ivec2(j + 7u * p, i.y), h);
#else
    store_global(offset + ((j + 0u * p) >> FFT_OUTPUT_SHIFT), a);
    store_global(offset + ((j + 1u * p) >> FFT_OUTPUT_SHIFT), e);
    store_global(offset + ((j + 2u * p) >> FFT_OUTPUT_SHIFT), c);
    store_global(offset + ((j + 3u * p) >> FFT_OUTPUT_SHIFT), g);
    store_global(offset + ((j + 4u * p) >> FFT_OUTPUT_SHIFT), b);
    store_global(offset + ((j + 5u * p) >> FFT_OUTPUT_SHIFT), f);
    store_global(offset + ((j + 6u * p) >> FFT_OUTPUT_SHIFT), d);
    store_global(offset + ((j + 7u * p) >> FFT_OUTPUT_SHIFT), h);
#endif
}

void FFT8_vert(uvec2 i, uint p)
{
    uvec2 octa_samples = gl_NumWorkGroups.xy * gl_WorkGroupSize.xy;
    uint stride = uStride;
    uint y_stride = stride * octa_samples.y;
    uint offset = stride * i.y;

    cfloat a = load_global(offset + i.x + 0u * y_stride);
    cfloat b = load_global(offset + i.x + 1u * y_stride);
    cfloat c = load_global(offset + i.x + 2u * y_stride);
    cfloat d = load_global(offset + i.x + 3u * y_stride);
    cfloat e = load_global(offset + i.x + 4u * y_stride);
    cfloat f = load_global(offset + i.x + 5u * y_stride);
    cfloat g = load_global(offset + i.x + 6u * y_stride);
    cfloat h = load_global(offset + i.x + 7u * y_stride);

    FFT8(a, b, c, d, e, f, g, h, i.y, p);

    uint k = i.y & (p - 1u);
    uint j = ((i.y - k) * 8u) + k;

#ifdef FFT_OUTPUT_IMAGE
    store(ivec2(i.x, j + 0u * p), a);
    store(ivec2(i.x, j + 1u * p), e);
    store(ivec2(i.x, j + 2u * p), c);
    store(ivec2(i.x, j + 3u * p), g);
    store(ivec2(i.x, j + 4u * p), b);
    store(ivec2(i.x, j + 5u * p), f);
    store(ivec2(i.x, j + 6u * p), d);
    store(ivec2(i.x, j + 7u * p), h);
#else
    store_global(stride * (j + 0u * p) + i.x, a);
    store_global(stride * (j + 1u * p) + i.x, e);
    store_global(stride * (j + 2u * p) + i.x, c);
    store_global(stride * (j + 3u * p) + i.x, g);
    store_global(stride * (j + 4u * p) + i.x, b);
    store_global(stride * (j + 5u * p) + i.x, f);
    store_global(stride * (j + 6u * p) + i.x, d);
    store_global(stride * (j + 7u * p) + i.x, h);
#endif
}


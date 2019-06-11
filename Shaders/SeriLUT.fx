// -------------------------------------
// SeriLUT © 2019 seri14
// -------------------------------------
// Based on BradLarson/GPUImage (https://github.com/BradLarson/GPUImage)
// Copyright (c) 2012, Brad Larson, Ben Cochran, Hugues Lismonde, Keitaroh Kobayashi, Alaric Cole, Matthew Clark, Jacob Gundersen, Chris Williams.
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 
// Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// Neither the name of the GPUImage framework nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
// -------------------------------------

#include "ReShade.fxh"

uniform int fLUT_Selector <
	ui_type = "combo";
	ui_items = "[ 1] High Aetherity\0"
	           "[ 2] Night of Anime\0"
	           "[ 3] Summer Light\0"
	           "[ 4] Lost Memory\0"
	           "[ 5] East Style\0"
	           "[ 6] Good Day\0";
	ui_label = "Use LUT";
> = 0;

uniform float fLUT_Intensity <
	ui_type = "slider";
	ui_min = 0.0; ui_max = 1.0;
	ui_label = "Intensity";
	ui_tooltip = "Intensity to blend color.";
> = 1.0;

texture LUT_1Tex < source = "high_aetherity_20190206_1.png"; > { Width = 512; Height = 512; };
texture LUT_2Tex < source = "night_of_anime_20190206_1.png"; > { Width = 512; Height = 512; };
texture LUT_3Tex < source = "summer_light_20190206_1.png"; > { Width = 512; Height = 512; };
texture LUT_4Tex < source = "lost_memory_20190206_1.png"; > { Width = 512; Height = 512; };
texture LUT_5Tex < source = "east_style_20190213_1.png"; > { Width = 512; Height = 512; };
texture LUT_6Tex < source = "good_day_20190217_1.png"; > { Width = 512; Height = 512; };

sampler LUT_1Sampler { Texture = LUT_1Tex; };
sampler LUT_2Sampler { Texture = LUT_2Tex; };
sampler LUT_3Sampler { Texture = LUT_3Tex; };
sampler LUT_4Sampler { Texture = LUT_4Tex; };
sampler LUT_5Sampler { Texture = LUT_5Tex; };
sampler LUT_6Sampler { Texture = LUT_6Tex; };

float4 macro_textureColor(float2 texcoord)
{
	[branch]
	switch (fLUT_Selector)
	{
	case 0: return tex2D(LUT_1Sampler, texcoord);
	case 1: return tex2D(LUT_2Sampler, texcoord);
	case 2: return tex2D(LUT_3Sampler, texcoord);
	case 3: return tex2D(LUT_4Sampler, texcoord);
	case 4: return tex2D(LUT_5Sampler, texcoord);
	case 5: return tex2D(LUT_6Sampler, texcoord);
	}
	return tex2D(LUT_1Sampler, texcoord);
}

float4 PS_GPUImageLUT(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float4 textureColor = tex2D(ReShade::BackBuffer, texcoord);

	float blueColor = textureColor.b * 63.0;

	float2 quad1;
	quad1.y = floor(floor(blueColor) / 8.0);
	quad1.x = floor(blueColor) - quad1.y * 8.0;

	float2 quad2;
	quad2.y = floor(ceil(blueColor) / 8.0);
	quad2.x = ceil(blueColor) - quad2.y * 8.0;

	float2 texPos1 = quad1.xy * 0.125 + 0.5 / 512.0 + (0.125 - 1.0 / 512.0) * textureColor.rg;
	float2 texPos2 = quad2.xy * 0.125 + 0.5 / 512.0 + (0.125 - 1.0 / 512.0) * textureColor.rg;

	float4 newColor1 = macro_textureColor(texPos1);
	float4 newColor2 = macro_textureColor(texPos2);

	float4 newColor = lerp(newColor1, newColor2, frac(blueColor));
	return lerp(textureColor, newColor, fLUT_Intensity);
}

technique SeriLUT
{
	pass GPUImageLUT
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_GPUImageLUT;
	}
}

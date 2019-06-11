// -------------------------------------
// SeriLUT (c) 2019 seri14
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

uniform float fLUT_Intensity <
	ui_min = 0.0; ui_max = 1.0; ui_step = (2.5 / 100.0);
	ui_type = "slider"; ui_label = "Intensity";
> = 1.0;

#include "ReShade.fxh"

texture __SERILUT_ID < source = __SERILUT_SOURCE; > { Width = 512; Height = 512; Format = RGBA8; };
sampler Sampler { Texture = __SERILUT_ID; };

texture __SERILUT_BEFORE_ID { Width = BUFFER_WIDTH; Height = BUFFER_HEIGHT; Format = RGBA8; };
sampler Sampler_Before { Texture = __SERILUT_BEFORE_ID; };

void PS_GPUImageLUT(float4 pos : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target)
{
	float4 backColor = tex2D(ReShade::BackBuffer, texcoord);
	float4 textureColor = tex2D(Sampler_Before, texcoord);

	float blueColor = textureColor.b * 63.0;

	float2 quad1;
	quad1.y = floor(floor(blueColor) / 8.0);
	quad1.x = floor(blueColor) - quad1.y * 8.0;

	float2 quad2;
	quad2.y = floor(ceil(blueColor) / 8.0);
	quad2.x = ceil(blueColor) - quad2.y * 8.0;

	float2 texPos1 = quad1.xy * 0.125 + 0.5 / 512.0 + (0.125 - 1.0 / 512.0) * textureColor.rg;
	float2 texPos2 = quad2.xy * 0.125 + 0.5 / 512.0 + (0.125 - 1.0 / 512.0) * textureColor.rg;

	float4 newColor1 = tex2D(Sampler, texPos1);
	float4 newColor2 = tex2D(Sampler, texPos2);

	float4 newColor = lerp(newColor1, newColor2, frac(blueColor));
	float  depth = ReShade::GetLinearizedDepth(texcoord);

	color = lerp(backColor, newColor, step(1.0, depth) * fLUT_Intensity);
	color.a = backColor.a;
}

float4 PS_SeriLUT_Before(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	return tex2D(ReShade::BackBuffer, texcoord);
}

technique __SERILUT_ID < ui_label = __SERILUT_LABEL; >
{
	pass GPUImageLUT
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_GPUImageLUT;
	}
}

technique __SERILUT_BEFORE_ID < ui_label = __SERILUT_BEFORE_LABEL; >
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_SeriLUT_Before;
		RenderTarget = __SERILUT_BEFORE_ID;
	}
}

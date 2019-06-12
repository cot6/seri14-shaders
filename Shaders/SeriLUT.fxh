// SeriLUT (c) 2019 seri14
// -------------------------------------
// 
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
// 
// -------------------------------------
// 

uniform float fLUT_Intensity <
	ui_min = 0.0; ui_max = 1.0; ui_step = (1.0 / 100.0);
	ui_type = "slider"; ui_label = "Intensity";
> = 1.0;

#include "ReShade.fxh"

texture __SERILUT_ID < source = __SERILUT_SOURCE; > { Width = 512; Height = 512; Format = RGBA8; };
sampler Sampler { Texture = __SERILUT_ID; };

void PS_GPUImageLUT(float4 vars : SV_Position, float2 texCoord : TEXCOORD, out float4 back : SV_Target)
{
	back = tex2D(ReShade::BackBuffer, texCoord);
	float blueTable = back.b * 63.0;

	vars.x = floor(blueTable);
	vars.z = ceil(blueTable);

	vars.yw = floor(vars.xz * 0.125);
	vars.xz = vars.xz - vars.yw * 8.0;

	vars = (vars + back.rgrg * 0.984375 + 0.0078125) * 0.125;
	vars = lerp(tex2D(Sampler, vars.xy), tex2D(Sampler, vars.zw), frac(blueTable));

	vars.a = back.a;
	back = lerp(back, vars, fLUT_Intensity);
}

technique __SERILUT_ID < ui_label = __SERILUT_LABEL; >
{
	pass GPUImageLUT
	{
		VertexShader = PostProcessVS;
		PixelShader = PS_GPUImageLUT;
	}
}

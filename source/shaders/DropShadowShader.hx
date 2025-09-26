package shaders;

import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.math.FlxAngle;
import flixel.graphics.frames.FlxFrame;
import openfl.display.BitmapData;

/**
 * DropShadowShader (P-Slice → Psych adapted)
 * - Adds rim-lighting/drop-shadow effect to sprites.
 * - Includes AdjustColor controls (hue, saturation, brightness, contrast).
 * - Supports optional alternate mask images with threshold override.
 */
class DropShadowShader extends FlxShader
{
	// Public fields
	public var color(default, set):FlxColor;
	public var angle(default, set):Float;
	public var distance(default, set):Float;
	public var strength(default, set):Float;
	public var threshold(default, set):Float;
	public var antialiasAmt(default, set):Float;

	public var useAltMask(default, set):Bool;
	public var altMaskImage(default, set):BitmapData;
	public var maskThreshold(default, set):Float;

	public var attachedSprite(default, set):FlxSprite;

	// AdjustColor fields
	public var baseHue(default, set):Float;
	public var baseSaturation(default, set):Float;
	public var baseBrightness(default, set):Float;
	public var baseContrast(default, set):Float;

	// Quick batch setter
	public function setAdjustColor(b:Float, h:Float, c:Float, s:Float)
	{
		baseBrightness = b;
		baseHue = h;
		baseContrast = c;
		baseSaturation = s;
	}

	// Setters
	function set_color(col:FlxColor):FlxColor {
		color = col;
		dropColor.value = [color.red / 255, color.green / 255, color.blue / 255];
		return color;
	}
	function set_angle(val:Float):Float {
		angle = val;
		ang.value = [angle * FlxAngle.TO_RAD];
		return angle;
	}
	function set_distance(val:Float):Float {
		distance = val;
		dist.value = [val];
		return val;
	}
	function set_strength(val:Float):Float {
		strength = val;
		str.value = [val];
		return val;
	}
	function set_threshold(val:Float):Float {
		threshold = val;
		thr.value = [val];
		return val;
	}
	function set_antialiasAmt(val:Float):Float {
		antialiasAmt = val;
		AA_STAGES.value = [val];
		return val;
	}
	function set_maskThreshold(val:Float):Float {
		maskThreshold = val;
		thr2.value = [val];
		return val;
	}
	function set_useAltMask(val:Bool):Bool {
		useAltMask = val;
		useMask.value = [val];
		return val;
	}
	function set_altMaskImage(bmp:BitmapData):BitmapData {
		altMask.input = bmp;
		return bmp;
	}
	function set_attachedSprite(spr:FlxSprite):FlxSprite {
		attachedSprite = spr;
		if (spr != null) updateFrameInfo(spr.frame);
		return spr;
	}

	// AdjustColor setters
	function set_baseHue(val:Float):Float { baseHue = val; hue.value = [val]; return val; }
	function set_baseSaturation(val:Float):Float { baseSaturation = val; saturation.value = [val]; return val; }
	function set_baseBrightness(val:Float):Float { baseBrightness = val; brightness.value = [val]; return val; }
	function set_baseContrast(val:Float):Float { baseContrast = val; contrast.value = [val]; return val; }

	// Frame sync
	public function onAttachedFrame(name:String, frameNum:Int, frameIndex:Int):Void {
		if (attachedSprite != null) updateFrameInfo(attachedSprite.frame);
	}
	public function updateFrameInfo(frame:FlxFrame):Void {
		uFrameBounds.value = [frame.uv.x, frame.uv.y, frame.uv.width, frame.uv.height];
		angOffset.value = [frame.angle * FlxAngle.TO_RAD];
	}

	// Load alternate mask image
	public function loadAltMask(path:String):Void {
		#if html5
		BitmapData.loadFromFile(path).onComplete(function(bmp:BitmapData) {
			altMaskImage = bmp;
		});
		#else
		altMaskImage = BitmapData.fromFile(path);
		#end
	}

	// Shader GLSL
	@:glFragmentSource('
		#pragma header
		uniform vec4 uFrameBounds;
		uniform float ang;
		uniform float dist;
		uniform float str;
		uniform float thr;
		uniform float angOffset;

		uniform sampler2D altMask;
		uniform bool useMask;
		uniform float thr2;

		uniform vec3 dropColor;
		uniform float hue;
		uniform float saturation;
		uniform float brightness;
		uniform float contrast;
		uniform float AA_STAGES;

		const vec3 grayscaleValues = vec3(0.3098, 0.6078, 0.0823);
		const float e = 2.718281828459045;

		vec3 applyHueRotate(vec3 aColor, float aHue){
			float angle = radians(aHue);
			mat3 m1 = mat3(0.213,0.213,0.213, 0.715,0.715,0.715, 0.072,0.072,0.072);
			mat3 m2 = mat3(0.787,-0.213,-0.213, -0.715,0.285,-0.715, -0.072,-0.072,0.928);
			mat3 m3 = mat3(-0.213,0.143,-0.787, -0.715,0.140,0.715, 0.928,-0.283,0.072);
			mat3 m = m1 + cos(angle)*m2 + sin(angle)*m3;
			return m * aColor;
		}
		vec3 applySaturation(vec3 aColor, float value){
			if(value > 0.0) value *= 3.0;
			value = (1.0 + (value / 100.0));
			vec3 grayscale = vec3(dot(aColor, grayscaleValues));
			return clamp(mix(grayscale, aColor, value),0.0,1.0);
		}
		vec3 applyContrast(vec3 aColor, float value){
			value = (1.0 + (value / 100.0));
			if(value > 1.0){
				value = (((0.00852259 * pow(e, 4.76454 * (value-1.0)))*1.01) - 0.0086078159)*10.0;
				value += 1.0;
			}
			return clamp((aColor-0.25)*value+0.25,0.0,1.0);
		}
		vec3 applyHSBC(vec3 color){
			color = color + (brightness / 255.0);
			color = applyHueRotate(color, hue);
			color = applyContrast(color, contrast);
			color = applySaturation(color, saturation);
			return color;
		}

		vec2 hash22(vec2 p){
			vec3 p3 = fract(vec3(p.xyx) * vec3(.1031,.1030,.0973));
			p3 += dot(p3,p3.yzx+33.33);
			return fract((p3.xx+p3.yz)*p3.zy);
		}
		float intensityPass(vec2 fragCoord, float curThr, bool useMask){
			vec4 col = flixel_texture2D(bitmap,fragCoord);
			float maskIntensity = 0.0;
			if(useMask) maskIntensity = mix(0.0,1.0,flixel_texture2D(altMask,fragCoord).b);
			if(col.a==0.0) return 0.0;
			float intensity = dot(col.rgb, grayscaleValues);
			return maskIntensity > 0.0 ? float(intensity > thr2) : float(intensity > thr);
		}
		float antialias(vec2 fragCoord, float curThr, bool useMask){
			const int MAX_AA = 8;
			float total = AA_STAGES*AA_STAGES + 1.0;
			const float JIT = 0.5;
			float color = intensityPass(fragCoord,curThr,useMask);
			for(int i=0;i<MAX_AA*MAX_AA;i++){
				int x=i/MAX_AA;
				int y=i-(MAX_AA*int(i/MAX_AA));
				if(float(x)>=AA_STAGES||float(y)>=AA_STAGES) continue;
				vec2 offset = JIT*(2.0*hash22(vec2(float(x),float(y)))-1.0)/openfl_TextureSize.xy;
				color += intensityPass(fragCoord+offset,curThr,useMask);
			}
			return color/total;
		}
		vec3 createDropShadow(vec3 col,float curThr,bool useMask){
			float intensity = antialias(openfl_TextureCoordv,curThr,useMask);
			vec2 imageRatio = vec2(1.0/openfl_TextureSize.x,1.0/openfl_TextureSize.y);
			vec2 checkedPixel = vec2(openfl_TextureCoordv.x+(dist*cos(ang+angOffset)*imageRatio.x),
									 openfl_TextureCoordv.y-(dist*sin(ang+angOffset)*imageRatio.y));
			float dropAmount=0.0;
			if(checkedPixel.x>uFrameBounds.x && checkedPixel.y>uFrameBounds.y
			&& checkedPixel.x<uFrameBounds.z && checkedPixel.y<uFrameBounds.w){
				dropAmount = flixel_texture2D(bitmap,checkedPixel).a;
			}
			col.rgb += dropColor.rgb*((1.0-(dropAmount*str))*intensity);
			return col;
		}
		void main(){
			vec4 col = flixel_texture2D(bitmap,openfl_TextureCoordv);
			vec3 unpremultiplied = col.a>0.0?col.rgb/col.a:col.rgb;
			vec3 outColor = applyHSBC(unpremultiplied);
			outColor = createDropShadow(outColor,thr,useMask);
			gl_FragColor = vec4(outColor.rgb*col.a,col.a);
		}
	')
	public function new() {
		super();
		// defaults
		color = FlxColor.WHITE;
		angle = 0;
		strength = 1;
		distance = 15;
		threshold = 0.1;
		antialiasAmt = 2;
		maskThreshold = 0.5;
		useAltMask = false;
		baseHue = 0;
		baseSaturation = 0;
		baseBrightness = 0;
		baseContrast = 0;
		angOffset.value = [0];
	}
}

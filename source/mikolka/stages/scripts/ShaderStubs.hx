package mikolka.stages.scripts;

import flixel.FlxSprite;
import flixel.system.FlxShader;

/**
 * Stub shader classes so TankErect/MallXmasErect can compile.
 * Replace with your own real shader implementations if desired.
 */
class DropShadowScreenspace extends FlxShader {
	public var angle:Float = 90;
	public function new() { super(); }
	public function setAdjustColor(a:Int, b:Int, c:Int, d:Int):Void {}
}

class DropShadowShader extends FlxShader {
	public var angle:Float = 90;
	public var color:UInt = 0xFFFFFFFF;
	public var attachedSprite:FlxSprite;
	public function new() { super(); }
	public function setAdjustColor(a:Int, b:Int, c:Int, d:Int):Void {}
}

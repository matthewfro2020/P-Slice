package mikolka.stages.cutscenes;

import mikolka.funkin.FlxAtlasSprite;
import mikolka.funkin.FunkinSound;
import openfl.filters.ShaderFilter;
import shaders.DropShadowScreenspace;
import mikolka.stages.erect.TankErect;
import flixel.math.FlxPoint;
#if !LEGACY_PSYCH
import cutscenes.CutsceneHandler;
#end

class GooeyTankman extends FlxAtlasSprite {
	public function new(stage:TankErect, x:Float, y:Float) {
		this.stage = stage;
		super(x, y, Paths.loadAnimateAtlas("erect/cutscene/StressCutTankGooey", "week7"), {
			FrameRate: 24.0,
			Reversed: false,
			// ?OnComplete:Void -> Void,
			ShowPivot: false,
			Antialiasing: true,
			ScrollFactor: new FlxPoint(1, 1),
		});
	}

	var cutsceneSounds:FunkinSound = null;

	public function cancelSounds() {
		if (cutsceneSounds != null)
			cutsceneSounds.destroy();
	}

	function doAnim() {
		playAnimation("StressGooeyTankman", true, false, false);
	}
}

package objects;

import objects.Character;
import states.PlayState;
import flixel.FlxSprite;
import flixel.util.FlxSpriteUtil;
import flixel.FlxG;
import backend.Conductor;

class KamSpeakerStressCharacter extends Character {
	var shootTimes:Array<Float> = [];
	var shootDirs:Array<Int> = [];

	public var flora:FlxSprite;
	public var floraLights:FlxSprite;
	public var floraCombo:FlxSprite;
	public var visualizerFlora:FlxSprite;

	var comboCheck:Bool = true;
	var defaultPoints:Array<Float> = [0.5,0.5,0.5,0.5,0.5,0.5,0.5];
	var points:Array<Float> = [];
	var lineStyle:LineStyle;
	var curve:Int = 0;

	public function new(x:Float = 0, y:Float = 0, isPlayer:Bool = false) {
		super(x, y, 'kam-speaker-stress', isPlayer);
		points = defaultPoints.copy();

		// Attach Flora speaker
		flora = new FlxSprite(x + 600, y + 670);
		flora.frames = Paths.getSparrowAtlas('characters/FloraSpeaker');
		flora.animation.addByPrefix('idle', 'floraBop', 12, false);
		flora.animation.play('idle');
		PlayState.instance.add(flora);

		// Lights
		floraLights = new FlxSprite(x + 570, y + 660);
		floraLights.frames = Paths.getSparrowAtlas('characters/FloraLights');
		floraLights.animation.addByPrefix('idle', 'lightBop', 12, false);
		floraLights.animation.play('idle');
		PlayState.instance.add(floraLights);

		// Combo
		floraCombo = new FlxSprite(x + 570, y + 660);
		floraCombo.frames = Paths.getSparrowAtlas('characters/FloraLights');
		floraCombo.animation.addByPrefix('50combo', '50combo', 24, false);
		floraCombo.animation.addByPrefix('200combo', '200combo', 24, false);
		floraCombo.animation.addByPrefix('lossCombo', 'lossCombo', 24, false);
		floraCombo.visible = false;
		PlayState.instance.add(floraCombo);

		// Visualizer dummy
		visualizerFlora = new FlxSprite(x + 900, y + 820).makeGraphic(115, 70, 0x00000000);
		visualizerFlora.visible = false;
		PlayState.instance.add(visualizerFlora);

		floraCombo.animation.finishCallback = function(_) {
			comboCheck = true;
			floraLights.visible = true;
			visualizerFlora.visible = true;
			floraCombo.visible = false;
		};
	}

	override public function dance():Void {
		super.dance();
		if (flora != null) flora.animation.play('idle', true);
		if (floraLights != null) floraLights.animation.play('idle', true);
	}

	// Psych uses PlayState.instance.combo for current combo
	public function checkCombo(broke:Bool = false) {
		if (!comboCheck) return;
		var combo = PlayState.instance.combo;

		if (combo == 50) triggerCombo('50combo');
		else if (combo == 200) triggerCombo('200combo');
		else if (broke && combo >= 70) triggerCombo('lossCombo');
	}

	private function triggerCombo(anim:String) {
		comboCheck = false;
		floraLights.visible = false;
		visualizerFlora.visible = false;
		floraCombo.visible = true;
		floraCombo.animation.play(anim, true);
	}

	override public function draw():Void {
		// Fake visualizer (simple wave bars)
		if (visualizerFlora != null) {
			FlxSpriteUtil.fill(visualizerFlora, 0);
			FlxSpriteUtil.drawRect(visualizerFlora, 0, 30, 115, 15, 0xFF6CFFFA);
		}
		super.draw();
	}
}

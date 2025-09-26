package objects;

import objects.Character;
import states.PlayState;
import flixel.FlxSprite;
import flixel.util.FlxSpriteUtil;
import flixel.FlxG;

class FloraSpeakerCharacter extends Character {
	public var floraLights:FlxSprite;
	public var floraCombo:FlxSprite;
	public var visualizerFlora:FlxSprite;

	public var comboActive:Bool = false;
	var defaultPoints:Array<Float> = [0.5,0.5,0.5,0.5,0.5,0.5,0.5];
	var points:Array<Float> = [];
	var lineStyle:LineStyle;

	public function new(x:Float, y:Float, isPlayer:Bool = false) {
		super(x, y, 'flora-speaker', isPlayer);
		points = defaultPoints.copy();

		floraLights = new FlxSprite(x, y);
		floraLights.frames = Paths.getSparrowAtlas('characters/FloraLights');
		floraLights.animation.addByPrefix('idle', 'lightBop', 12, false);
		floraLights.animation.play('idle');
		PlayState.instance.add(floraLights);

		floraCombo = new FlxSprite(x, y);
		floraCombo.frames = Paths.getSparrowAtlas('characters/FloraLights');
		floraCombo.animation.addByPrefix('50combo', '50combo', 24, false);
		floraCombo.animation.addByPrefix('200combo', '200combo', 24, false);
		floraCombo.animation.addByPrefix('lossCombo', 'lossCombo', 24, false);
		floraCombo.visible = false;
		PlayState.instance.add(floraCombo);

		visualizerFlora = new FlxSprite(x + 340, y + 160).makeGraphic(115, 70, 0x00000000);
		PlayState.instance.add(visualizerFlora);

		floraCombo.animation.finishCallback = function(_) {
			comboActive = false;
			floraLights.visible = true;
			visualizerFlora.visible = true;
			floraCombo.visible = false;
		};
	}

	override public function dance():Void {
		super.dance();
		if (floraLights != null) floraLights.animation.play('idle', true);
	}

	public function checkCombo(combo:Int, broke:Bool = false) {
		if (comboActive) return;
		if (combo == 50) triggerCombo('50combo');
		else if (combo == 200) triggerCombo('200combo');
		else if (broke && combo >= 70) triggerCombo('lossCombo');
	}

	private function triggerCombo(anim:String) {
		comboActive = true;
		floraLights.visible = false;
		visualizerFlora.visible = false;
		floraCombo.visible = true;
		floraCombo.animation.play(anim, true);
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);
		if (FlxG.sound.music != null) {
			points = [];
			var amp = Math.abs(FlxG.sound.music.amplitude);
			for (i in 0...defaultPoints.length) {
				var bar = amp + FlxG.random.float(-0.1, 0.1);
				points.push(Math.max(0.1, Math.min(1, bar)));
			}
		} else {
			points = defaultPoints.copy();
		}
	}

	override public function draw():Void {
		if (visualizerFlora != null) {
			FlxSpriteUtil.fill(visualizerFlora, 0);
			lineStyle = FlxSpriteUtil.getDefaultLineStyle({ thickness: 2, color: 0xFF6CFFFA });

			var oldX = 0;
			var oldY = visualizerFlora.height / 2;
			for (i in 0...points.length) {
				var x = Std.int((visualizerFlora.width / points.length) * (i + 1));
				var y = Std.int(visualizerFlora.height * (1 - points[i]));
				FlxSpriteUtil.flashGfx.moveTo(oldX, oldY);
				FlxSpriteUtil.flashGfx.lineTo(x, y);
				oldX = x;
				oldY = y;
			}

			FlxSpriteUtil.endDraw(visualizerFlora, null);
		}
		super.draw();
	}
}

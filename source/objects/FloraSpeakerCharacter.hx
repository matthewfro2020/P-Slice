package objects;

import objects.Character;
import states.PlayState;
import flixel.FlxSprite;
import flixel.FlxG;

class FloraSpeakerCharacter extends Character {
	public var floraLights:FlxSprite;
	public var floraCombo:FlxSprite;
	public var comboActive:Bool = false;

	public function new(x:Float, y:Float, isPlayer:Bool = false) {
		// Order on Psych 1.0.x: (x, y, characterId, isPlayer)
		super(x, y, 'flora-speaker', isPlayer);

		// Optional: nudge the base character
		this.x = x;
		this.y = y;

		// Lights sprite (animated via Sparrow)
		floraLights = new FlxSprite(x, y);
		floraLights.frames = Paths.getSparrowAtlas('characters/FloraLights');
		floraLights.antialiasing = ClientPrefs.data.antialiasing;
		floraLights.animation.addByPrefix('idle', 'lightBop', 12, false);
		floraLights.animation.play('idle'); if (floraLights.animation.curAnim != null) floraLights.animation.curAnim.finish();
		PlayState.instance.add(floraLights);

		// Combo sprite (same atlas; different anim names)
		floraCombo = new FlxSprite(x, y);
		floraCombo.frames = Paths.getSparrowAtlas('characters/FloraLights');
		floraCombo.antialiasing = ClientPrefs.data.antialiasing;
		floraCombo.animation.addByPrefix('50combo', '50combo', 24, false);
		floraCombo.animation.addByPrefix('200combo', '200combo', 24, false);
		floraCombo.animation.addByPrefix('lossCombo', 'lossCombo', 24, false);
		floraCombo.visible = false;
		PlayState.instance.add(floraCombo);

		// When combo anim finishes, restore the lights
		floraCombo.animation.finishCallback = function(_){
			comboActive = false;
			floraLights.visible = true;
			floraCombo.visible = false;
		}
	}

	override public function dance():Void {
		super.dance();
		if (floraLights != null)
			floraLights.animation.play('idle', true);
	}

	// Call this from PlayState when your combo changes
	public function checkCombo(combo:Int, broke:Bool = false) {
		if (comboActive) return;

		if (combo == 50) triggerCombo('50combo');
		else if (combo == 200) triggerCombo('200combo');
		else if (broke && combo >= 70) triggerCombo('lossCombo');
	}

	private function triggerCombo(anim:String) {
		comboActive = true;
		floraLights.visible = false;
		floraCombo.visible = true;
		floraCombo.animation.play(anim, true);
	}
}

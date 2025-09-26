package objects;

import objects.Character;
import states.PlayState;
import flixel.FlxSprite;

class FloraSpeakerChristmasCharacter extends Character {
	public var flora:FlxSprite;
	public var floraCombo:FlxSprite;
	public var christmas:FlxSprite;
	public var visualizerFlora:FlxSprite;
	public var comboFloraCheck:Bool = true;

	public function new(x:Float, y:Float, isPlayer:Bool = false) {
		super(x, y, 'flora-speaker', isPlayer);

		// Base pos
		this.x = x;
		this.y = y;

		// Christmas topper (Sparrow)
		christmas = new FlxSprite(x, y);
		christmas.frames = Paths.getSparrowAtlas('characters/FloraChristmas');
		christmas.animation.addByPrefix('idle', 'christmas', 12, false);
		christmas.animation.play('idle'); if (christmas.animation.curAnim != null) christmas.animation.curAnim.finish();
		PlayState.instance.add(christmas);

		// Lights (Sparrow)
		flora = new FlxSprite(x, y);
		flora.frames = Paths.getSparrowAtlas('characters/FloraLights');
		flora.animation.addByPrefix('idle', 'lightBop', 12, false);
		flora.animation.play('idle'); if (flora.animation.curAnim != null) flora.animation.curAnim.finish();
		PlayState.instance.add(flora);

		// Combo (Sparrow)
		floraCombo = new FlxSprite(x, y);
		floraCombo.frames = Paths.getSparrowAtlas('characters/FloraLights');
		floraCombo.animation.addByPrefix('50combo', '50combo', 24, false);
		floraCombo.animation.addByPrefix('200combo', '200combo', 24, false);
		floraCombo.animation.addByPrefix('lossCombo', 'lossCombo', 24, false);
		floraCombo.visible = false;
		PlayState.instance.add(floraCombo);

		// Visualizer dummy (solid because we’re not drawing on it here)
		visualizerFlora = new FlxSprite(x + 342, y + 172).makeGraphic(115, 70, 0x00000000);
		PlayState.instance.add(visualizerFlora);

		floraCombo.animation.finishCallback = function(_){
			comboFloraCheck = true;
			flora.visible = true;
			visualizerFlora.visible = true;
			floraCombo.visible = false;
		}
	}

	override public function dance():Void {
		super.dance();
		if (flora != null) flora.animation.play('idle', true);
		if (christmas != null) christmas.animation.play('idle', true);
	}

	// Call from PlayState when combo changes
	public function checkCombo(combo:Int, broke:Bool = false) {
		if (!comboFloraCheck) return;

		if (combo == 50) triggerCombo('50combo');
		else if (combo == 200) triggerCombo('200combo');
		else if (broke && combo >= 70) triggerCombo('lossCombo');
	}

	private function triggerCombo(anim:String) {
		comboFloraCheck = false;
		flora.visible = false;
		visualizerFlora.visible = false;
		floraCombo.visible = true;
		floraCombo.animation.play(anim, true);
	}
}

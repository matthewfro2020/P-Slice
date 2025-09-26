package objects;

import objects.Character;
import flixel.FlxG;

/**
 * Psych 1.0.x–compatible Kam Speaker Stress character.
 * Keep simple: idle on beat. (No onNote* overrides in Psych Character)
 */
class KamSpeakerStressCharacter extends Character {
	public function new(x:Float = 0, y:Float = 0, isPlayer:Bool = false) {
		// Order: x, y, characterId, isPlayer
		super(x, y, 'kam-speaker-stress', isPlayer);
		this.x = x;
		this.y = y;
		antialiasing = ClientPrefs.data.antialiasing;
	}

	override public function dance():Void {
		super.dance();
		// If your JSON defines idle, this keeps him bopping
		playAnim('idle', true);
	}
}

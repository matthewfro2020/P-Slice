package objects;

import objects.Character;
import flixel.FlxSprite;
import flixel.FlxG;

/**
 * Psych Engine–compatible Kam Speaker Stress character.
 */
class KamSpeakerStressCharacter extends Character
{
    public function new(x:Float, y:Float, isPlayer:Bool)
    {
        super(x, y, isPlayer, 'kam-speaker-stress');

        // Scale/offset adjustments if needed
        antialiasing = true;
    }

    override public function dance():Void
    {
        // Call base class dance
        super.dance();

        // Add extra behavior if you want custom animations to loop on beat
        playAnim('idle', true);
    }

    override public function onNoteHit(note:Note):Void
    {
        super.onNoteHit(note);

        switch (note.noteData)
        {
            case 0: playAnim('singLEFT', true);
            case 1: playAnim('singDOWN', true);
            case 2: playAnim('singUP', true);
            case 3: playAnim('singRIGHT', true);
        }
    }

    override public function onNoteMiss(note:Note):Void
    {
        super.onNoteMiss(note);

        // Optional miss animations if you define them
        switch (note.noteData)
        {
            case 0: if (hasAnimation('singLEFTmiss')) playAnim('singLEFTmiss', true);
            case 1: if (hasAnimation('singDOWNmiss')) playAnim('singDOWNmiss', true);
            case 2: if (hasAnimation('singUPmiss')) playAnim('singUPmiss', true);
            case 3: if (hasAnimation('singRIGHTmiss')) playAnim('singRIGHTmiss', true);
        }
    }
}

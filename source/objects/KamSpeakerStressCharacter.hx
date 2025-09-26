package objects;

import objects.Character;
import states.PlayState;

class KamSpeakerStressCharacter extends Character
{
    public function new(x:Float, y:Float, isPlayer:Bool = false)
    {
        super(x, y, 'kam-speaker-stress', isPlayer);
        this.playAnim('idle', true);
    }

    // Called when note data tells Kam to shoot
    public function playShoot(direction:Int)
    {
        switch (direction)
        {
            case 0: playAnim('shoot1', true);
            case 1: playAnim('shoot2', true);
            case 2: playAnim('shoot3', true);
            case 3: playAnim('shoot4', true);
        }
    }

    override public function dance(force:Bool = false)
    {
        if (getAnimationName().startsWith("shoot")) return; // don’t interrupt shooting
        super.dance(force);
    }
}

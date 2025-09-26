package objects;

import objects.Character;
import flixel.FlxSprite;
import flixel.FlxG;
import states.PlayState;

class FloraSpeakerCharacter extends Character
{
    public var floraLights:FlxSprite;
    public var floraCombo:FlxSprite;
    public var comboActive:Bool = false;

    public function new(x:Float, y:Float, isPlayer:Bool = false)
    {
        super(x, y, 'flora-speaker', isPlayer);

        // Extra "lights" sprite
        floraLights = new FlxSprite(x, y).loadGraphic(Paths.image('characters/FloraLights'));
        floraLights.antialiasing = ClientPrefs.data.antialiasing;
        PlayState.instance.add(floraLights);

        // Combo animation sprite
        floraCombo = new FlxSprite(x, y).loadGraphic(Paths.image('characters/FloraLights'));
        floraCombo.antialiasing = ClientPrefs.data.antialiasing;
        floraCombo.visible = false;
        PlayState.instance.add(floraCombo);
    }

    override public function dance(force:Bool = false)
    {
        super.dance(force);
        if (floraLights != null)
            floraLights.animation.play('idle', true);
    }

    public function checkCombo(combo:Int, broke:Bool = false)
    {
        if (comboActive) return;

        if (combo == 50)
        {
            triggerCombo("50combo");
        }
        else if (combo == 200)
        {
            triggerCombo("200combo");
        }
        else if (broke && combo >= 70)
        {
            triggerCombo("lossCombo");
        }
    }

    private function triggerCombo(anim:String)
    {
        comboActive = true;
        floraLights.visible = false;
        floraCombo.visible = true;
        floraCombo.animation.play(anim, true);

        floraCombo.animation.finishCallback = function(_)
        {
            comboActive = false;
            floraLights.visible = true;
            floraCombo.visible = false;
        }
    }
}

package objects;

import states.PlayState;
import flixel.FlxSprite;
import flixel.util.FlxSpriteUtil;

class FloraSpeakerChristmasCharacter extends Character
{
    public var flora:FlxSprite;
    public var floraCombo:FlxSprite;
    public var christmas:FlxSprite;
    public var visualizerFlora:FlxSprite;
    public var comboFloraCheck:Bool = true;
    public var refreshedLol:Bool = false;

    public function new(x:Float, y:Float, isPlayer:Bool = false)
    {
        super(x, y, 'flora-speaker-christmas', isPlayer);

        // Christmas sprite
        christmas = new FlxSprite(x, y).loadGraphic(Paths.image('characters/FloraChristmas'));
        add(christmas);

        // Lights
        flora = new FlxSprite(x, y).loadGraphic(Paths.image('characters/FloraLights'));
        add(flora);

        // Combo animations
        floraCombo = new FlxSprite(x, y).loadGraphic(Paths.image('characters/FloraLights'));
        floraCombo.visible = false;
        add(floraCombo);

        // Visualizer dummy
        visualizerFlora = new FlxSprite().makeGraphic(115, 70, 0xFF000000);
        add(visualizerFlora);
    }

    override public function dance()
    {
        super.dance();
        if (flora != null) flora.animation.play('idle', true);
        if (christmas != null) christmas.animation.play('idle', true);
    }

    public function checkCombo(combo:Int, broke:Bool = false)
    {
        if (!comboFloraCheck) return;

        if (combo == 50)
        {
            triggerCombo('50combo');
        }
        else if (combo == 200)
        {
            triggerCombo('200combo');
        }
        else if (broke && combo >= 70)
        {
            triggerCombo('lossCombo');
        }
    }

    private function triggerCombo(anim:String)
    {
        comboFloraCheck = false;
        flora.visible = false;
        visualizerFlora.visible = false;
        floraCombo.visible = true;
        floraCombo.animation.play(anim, true);

        floraCombo.animation.finishCallback = function(_)
        {
            comboFloraCheck = true;
            flora.visible = true;
            visualizerFlora.visible = true;
            floraCombo.visible = false;
        }
    }
}

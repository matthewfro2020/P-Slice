package mikolka.stages.scripts;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;

import states.PlayState;
import backend.BaseStage;

/**
 * Handles Gooey/Pico variations of Stress.
 * Cutscene logic and overlays.
 */
class StressSongPSlice
{
    public static function register():StressSongPSlice
    {
        return new StressSongPSlice();
    }

    var PS:PlayState;
    var cutsceneSprite:FlxSprite;
    var cutsceneTimer:FlxTimer;
    var hasPlayedCutscene:Bool = false;

    public function new()
    {
        PS = PlayState.instance;
    }

    // called when TankErect detects a stress song
    public function onCreate():Void
    {
        cutsceneSprite = new FlxSprite().loadGraphic(Paths.image("erect/stressCutsceneOverlay"));
        cutsceneSprite.scrollFactor.set();
        cutsceneSprite.alpha = 0;
        PS.add(cutsceneSprite);
    }

    public function onCountdownStart():Void
    {
        if (hasPlayedCutscene) return;

        hasPlayedCutscene = true;
        PS.inCutscene = true;

        // fade in cutscene overlay
        FlxG.camera.flash(FlxColor.BLACK, 1);
        cutsceneSprite.alpha = 1;

        cutsceneTimer = new FlxTimer().start(3, function(tmr:FlxTimer)
        {
            skipCutscene();
        });
    }

    public function onUpdate(elapsed:Float):Void
    {
        if (PS.inCutscene && cutsceneSprite != null && cutsceneSprite.alpha > 0)
        {
            cutsceneSprite.alpha -= elapsed * 0.25;
            if (cutsceneSprite.alpha <= 0) cutsceneSprite.visible = false;
        }
    }

    public function skipCutscene():Void
    {
        if (cutsceneTimer != null) cutsceneTimer.cancel();

        if (cutsceneSprite != null)
        {
            cutsceneSprite.visible = false;
            cutsceneSprite.alpha = 0;
        }

        PS.inCutscene = false;
        PS.startCountdown();
    }

    public function onSongEndRequest():Bool
    {
        // block endSong until cutscene is finished
        if (PS.inCutscene)
        {
            skipCutscene();
            return true;
        }
        return false;
    }
}

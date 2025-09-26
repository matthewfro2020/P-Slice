package mikolka.stages.scripts;

import states.PlayState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import shaders.AdjustColorShader;

/**
 * Handles Stress gooey cutscene + mechanics (Psych 1.0.4 fixed)
 */
class StressSongPSlice {
    public static var instance:StressSongPSlice;
    var PS:PlayState;

    var hasPlayedCutscene:Bool = false;
    var cutsceneTimer:FlxTimer;
    var bgSprite:FlxSprite;

    public static function register():StressSongPSlice {
        if (instance == null) instance = new StressSongPSlice();
        return instance;
    }

    public function new() {
        PS = PlayState.instance;
    }

    // Called from TankErect.new()
    public function onCreate():Void {
        var song = PS.SONG.song.toLowerCase();
        if (song.contains("stress")) {
            trace("StressSongPSlice: onCreate called for " + song);
        }
    }

    // Start countdown setup
    public function onCountdownStart():Void {
        var song = PS.SONG.song.toLowerCase();

        if (song.contains("gooey") && !hasPlayedCutscene) {
            hasPlayedCutscene = true;
            startCutscene();
        }
    }

    public function onUpdate(elapsed:Float):Void {
        // If running a cutscene, tick its timer
        if (PS.inCutscene && cutsceneTimer != null) {
            cutsceneTimer.active = true;
        }

        // Skip cutscene manually if player presses ACCEPT (ENTER)
        if (PS.inCutscene && PS.controls.ACCEPT) {
            skipCutscene();
            endCutscene();
        }
    }

    // Called on beat updates if needed
    public function skipCutscene():Void {
        if (PS.inCutscene) {
            PS.inCutscene = false;
            if (bgSprite != null) {
                PS.remove(bgSprite, true);
                bgSprite = null;
            }
            if (cutsceneTimer != null) {
                cutsceneTimer.cancel();
                cutsceneTimer = null;
            }
            trace("StressSongPSlice: Cutscene skipped");
        }
    }

    public function onSongEndRequest():Bool {
        // Prevent auto-ending if still in cutscene
        if (PS.inCutscene) {
            skipCutscene();
            return true;
        }
        return false;
    }

    // ── Cutscene setup ───────────────────────────────
    function startCutscene():Void {
        PS.inCutscene = true;
        trace("StressSongPSlice: starting gooey cutscene");

        // Shader effect (optional)
        var shader = new AdjustColorShader();
        shader.brightness = -10;
        shader.saturation = -20;
        bgSprite.shader = shader;

        // Fake timer that will end cutscene after ~5s
        cutsceneTimer = new FlxTimer().start(5, function(tmr:FlxTimer) {
            endCutscene();
        });
    }

    function endCutscene():Void {
        trace("StressSongPSlice: ending gooey cutscene");
        skipCutscene();

        // Start the song countdown if still in cutscene phase
        if (PS.inCutscene) PS.inCutscene = false;
        if (!PS.startedCountdown) {
            PS.startCountdown();
        }
    }
}

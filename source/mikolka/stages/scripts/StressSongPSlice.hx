package mikolka.stages.scripts;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.text.FlxText;
import states.PlayState;

/**
 * Handles Gooey/Pico Stress mix events & cutscenes.
 */
class StressSongPSlice {
    public static var instance:StressSongPSlice;
    var PS:PlayState;

    var cutsceneTimer:FlxTimer;
    var hasPlayedCutscene:Bool = false;
    var bgSprite:FlxSprite;

    public static function register():StressSongPSlice {
        if (instance == null) instance = new StressSongPSlice();
        return instance;
    }

    public function new() {
        PS = PlayState.instance;
    }

    // ───────────────────────────────
    // Hooks
    // ───────────────────────────────
    public function onCreate() {
        // init background cutscene sprite
        bgSprite = new FlxSprite(0, 0).loadGraphic(Paths.image("stress/gooey_cutscene"));
        bgSprite.scrollFactor.set();
        bgSprite.visible = false;
        PS.add(bgSprite);
    }

    public function onCountdownStart() {
        if (PS == null) return;

        var song = PS.SONG.song.toLowerCase();
        if ((song.contains("gooey") || song.contains("pico")) && !hasPlayedCutscene) {
            startCutscene(song);
            hasPlayedCutscene = true;
        }
    }

    public function onUpdate(elapsed:Float) {
        if (PS == null) return;

        if (PS.inCutscene && cutsceneTimer != null)
            cutsceneTimer.update(elapsed);
    }

    public function onSongEndRequest():Bool {
        var song = PS.SONG.song.toLowerCase();
        if (song.contains("gooey")) {
            // block ending until cutscene finishes
            if (PS.inCutscene) return true;
        }
        return false;
    }

    // ───────────────────────────────
    // Cutscene Logic
    // ───────────────────────────────
    function startCutscene(variation:String) {
        PS.inCutscene = true;

        bgSprite.visible = true;
        bgSprite.cameras = [PS.camHUD];

        // fade in
        FlxTween.tween(bgSprite, {alpha: 1}, 1, {ease: FlxEase.quadInOut});

        cutsceneTimer = new FlxTimer().start(8, function(_) {
            endCutscene();
        });
    }

    public function skipCutscene() {
        if (!PS.inCutscene) return;
        if (cutsceneTimer != null) cutsceneTimer.cancel();
        endCutscene();
    }

    function endCutscene() {
        bgSprite.visible = false;
        PS.inCutscene = false;
    }
}

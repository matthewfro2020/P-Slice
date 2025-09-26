package mikolka.stages.scripts;

import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.text.FlxTextBorderStyle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.util.FlxTimerManager;
import openfl.display.BitmapData;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxG;

import states.PlayState;
import backend.BaseStage;
import objects.Character;

/**
 * Handles cutscene logic for Stress variations (gooey, pico).
 * Backend-friendly port for P-Slice.
 */
class StressSongPSlice {
    var hasPlayedCutscene:Bool = false;
    var hasPlayedEndCutscene:Bool = false;
    var cutsceneSkipped:Bool = false;
    var canSkipCutscene:Bool = false;

    var skipText:FlxText;
    var bgSprite:FlxSprite;

    var cutsceneTimerManager:FlxTimerManager;
    var cutsceneMusic:FlxSound;
    var gooeyCutSound:FlxSound;

    public var songId:String = "stress";

    public function new() {}

    // ── Hooks ──────────────────────────────────
    public function onCreate():Void {
        hasPlayedCutscene = false;
        hasPlayedEndCutscene = false;
        cutsceneSkipped = false;
        canSkipCutscene = false;
    }

    public function onRetry():Void {
        hasPlayedCutscene = true;
    }

    public function onCountdownStart():Void {
        var PS = PlayState.instance;
        if (PS == null) return;

        if (PS.currentVariation == 'gooey' && !hasPlayedCutscene) {
            preloadGooeyStressCutscene();
            gooeyStressCutscene();
            return;
        }
        var isPico = (PS.currentVariation == 'pico');
        if (!isPico) hasPlayedCutscene = true;
        if (!hasPlayedCutscene) {
            hasPlayedCutscene = true;
            startVideo(isPico);
        }
    }

    public function onUpdate(elapsed:Float):Void {
        var PS = PlayState.instance;
        if (PS == null) return;

        // ✅ Automatic skip handling
        if (PS.isInCutscene && PS.currentVariation == 'gooey') {
            if (PS.controls.ACCEPT && !cutsceneSkipped) {
                if (!canSkipCutscene) {
                    if (skipText != null) FlxTween.tween(skipText, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
                    new FlxTimer().start(0.5, _ -> canSkipCutscene = true);
                } else {
                    skipCutscene();
                }
            }
        }

        if (PS.isInCutscene && cutsceneTimerManager != null) cutsceneTimerManager.update(elapsed);
    }

    public function onSongEndRequest():Bool {
        var PS = PlayState.instance;
        if (PS == null) return false;

        if (PS.currentVariation == 'pico') return false;
        if (hasPlayedEndCutscene) { hasPlayedEndCutscene = false; return false; }
        hasPlayedEndCutscene = true;

        bgSprite = new FlxSprite(0,0);
        bgSprite.makeGraphic(2000, 2500, 0xFF000000);
        bgSprite.cameras = [PS.camCutscene];
        bgSprite.alpha = 0;
        PS.add(bgSprite);
        PS.refresh();

        startEndCutscene();
        return true;
    }

    // ── Video ──────────────────────────────────
    function startVideo(usePicoVideo:Bool):Void {
        var path = usePicoVideo ? 'stressPicoCutscene' : 'stressCutscene';
        FlxG.sound.play(path); // Replace with your video handler if available
    }

    // ── Gooey Intro Cutscene ───────────────────
    function preloadGooeyStressCutscene():Void {
        var PS = PlayState.instance;
        if (PS == null) return;

        skipText = new FlxText(936, 618, 0, 'Skip [ ENTER ]', 20);
        skipText.setFormat(Paths.font('vcr.ttf'), 40, 0xFFFFFFFF, "right", FlxTextBorderStyle.OUTLINE, 0xFF000000);
        skipText.alpha = 0;
        PS.add(skipText);

        PS.isInCutscene = true;
        if (PS.camHUD != null) PS.camHUD.visible = false;
    }

    function gooeyStressCutscene():Void {
        cutsceneTimerManager = new FlxTimerManager();

        new FlxTimer(cutsceneTimerManager).start(60/24, _ -> {
            gooeyCutSound = FlxG.sound.load(Paths.sound('stressGooeyCutscene/lines/2'));
            gooeyCutSound.play();
        });

        new FlxTimer(cutsceneTimerManager).start(635/24, _ -> {
            finalizeGooeyCutscene();
            PlayState.instance.startCountdown();
        });
    }

    function finalizeGooeyCutscene():Void {
        var PS = PlayState.instance;
        if (PS == null) return;

        canSkipCutscene = false;
        hasPlayedCutscene = true;
        cutsceneSkipped = true;
        PS.isInCutscene = false;
        if (PS.camHUD != null) PS.camHUD.visible = true;
        if (cutsceneMusic != null) cutsceneMusic.stop();
        if (skipText != null) skipText.visible = false;
    }

    // ── Skip Cutscene (public) ─────────────────
    public function skipCutscene():Void {
        var PS = PlayState.instance;
        if (PS == null || PS.currentVariation != 'gooey') return;

        cutsceneSkipped = true;
        hasPlayedCutscene = true;
        if (cutsceneMusic != null) cutsceneMusic.fadeOut(0.5, 0);
        if (gooeyCutSound != null) gooeyCutSound.fadeOut(0.5, 0);

        new FlxTimer().start(0.5, _ -> {
            PS.startCountdown();
            if (skipText != null) skipText.visible = false;
            PS.justUnpaused = true;
        });
    }

    // ── End Cutscene ───────────────────────────
    function startEndCutscene():Void {
        var PS = PlayState.instance;
        if (PS == null) return;

        cutsceneTimerManager = new FlxTimerManager();
        PS.isInCutscene = true;
        if (PS.camHUD != null) PS.camHUD.visible = false;

        var tankmanEnding = makeSparrowSprite('characters/TankmanEndingSprite');
        PS.add(tankmanEnding);

        new FlxTimer(cutsceneTimerManager).start(320/24, _ -> {
            PS.endSong(true);
        });
    }

    // ── Helpers ────────────────────────────────
    static function makeSparrowSprite(id:String):FlxSprite {
        var s = new FlxSprite();
        s.frames = FlxAtlasFrames.fromSparrow(BitmapData.fromFile(id+".png"), id+".xml");
        return s;
    }

    public static function register():StressSongPSlice {
        var b = new StressSongPSlice();
        return b;
    }
}

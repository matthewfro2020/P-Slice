package mikolka.stages.scripts;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.text.FlxTextBorderStyle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.util.FlxTimerManager;
import openfl.filters.ShaderFilter;
import openfl.display.BitmapData;
import flixel.graphics.frames.FlxAtlasFrames;

// ─────────────────────────────────────────────
// Engine-facing shims (minimal for P-Slice port)
// ─────────────────────────────────────────────
class PSPlayState {
  public static var instance(default, never):PSPlayState;
  public var camGame:FlxCamera;
  public var camHUD:FlxCamera;
  public var camCutscene:FlxCamera;
  public var isInCutscene:Bool = false;
  public var justUnpaused:Bool = false;
  public var currentVariation:String = "default";
  public var controls:PSControls;
  public var currentStage:PSStage;

  public function new() {}
  public function tweenCameraToPosition(x:Float, y:Float, dur:Float, ease:FlxEase->Float):Void {}
  public function tweenCameraZoom(z:Float, dur:Float, ?center:Bool = true, ease:FlxEase->Float):Void {}
  public function startCountdown():Void {}
  public function endSong(skipResults:Bool):Void {}
  public function add(s:FlxSprite):Void {}
  public function remove(s:FlxSprite):Void {}
  public function refresh():Void {}
}

class PSControls {
  public var CUTSCENE_ADVANCE:Bool;
  public function new() {}
  public function getDialogueNameFromToken(token:String, pretty:Bool):String return "Enter";
}

class PSStage {
  public function new() {}
  public function add(o:FlxSprite):Void {}
  public function remove(o:FlxSprite):Void {}
  public function refresh():Void {}
  public function getBoyfriend():PSChar return new PSChar();
  public function getGirlfriend():PSChar return new PSChar();
  public function getDad():PSChar return new PSChar();
}

class PSChar extends FlxSprite {
  public var cameraFocusPoint:FlxPoint = FlxPoint.get();
  public var curCharacter:String = "";
  public function playAnimation(name:String, force:Bool = false, ?ignoreIfPlaying:Bool = false):Void {}
}

class PSPaths {
  public static function sound(id:String, ?folder:String):String return id;
  public static function music(id:String, ?folder:String):String return id;
  public static function video(id:String):String return id;
  public static function font(id:String):String return id;
  public static function getSparrowAtlas(id:String):FlxAtlasFrames
    return FlxAtlasFrames.fromSparrow(BitmapData.fromFile(id+".png"), id+".xml");
}

class PSVideo { public static function play(path:String):Void {} }

class PSSound {
  public static function load(path:String, vol:Float = 1.0, loop:Bool = false):PSSound { return new PSSound(); }
  public var volume:Float = 1.0;
  public function new() {}
  public function play(loop:Bool):Void {}
  public function stop():Void {}
  public function fadeOut(dur:Float, to:Float):Void {}
}

class DropShadowScreenspace { public var angle:Float; public var threshold:Float; }
class DropShadowShader { public var angle:Float; public var color:UInt; public var attachedSprite:FlxSprite; public function new(){} public function setAdjustColor(a:Int,b:Int,c:Int,d:Int):Void{} }

// ─────────────────────────────────────────────
// Main StressSongPSlice class
// ─────────────────────────────────────────────
class StressSongPSlice {
  var hasPlayedCutscene:Bool = false;
  var hasPlayedEndCutscene:Bool = false;
  var cutsceneSkipped:Bool = false;
  var canSkipCutscene:Bool = false;

  var tankmanEnding:FlxSprite;
  var tankmanGooey:FlxSprite;
  var fakeTanks:FlxSprite;
  var fakeGooey:FlxSprite;

  var skipText:FlxText;
  var bgSprite:FlxSprite;

  var rimlightCamera:FlxCamera;
  var gooeyRimlightCamera:FlxCamera;

  var cutsceneTimerManager:FlxTimerManager;
  var cutsceneMusic:PSSound;
  var gooeyCutSound:PSSound;

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
    var PS = PSPlayState.instance;
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
    var PS = PSPlayState.instance;

    // ✅ Automatic skip handling
    if (PS.isInCutscene && PS.currentVariation == 'gooey') {
      if (PS.controls.CUTSCENE_ADVANCE && !cutsceneSkipped) {
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
    var PS = PSPlayState.instance;
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
    PSVideo.play(PSPaths.video(path));
  }

  // ── Gooey Intro Cutscene ───────────────────
  function preloadGooeyStressCutscene():Void {
    var PS = PSPlayState.instance;
    skipText = new FlxText(936, 618, 0, 'Skip [ ' + PS.controls.getDialogueNameFromToken("CUTSCENE_ADVANCE", true) + ' ]', 20);
    skipText.setFormat(PSPaths.font('vcr.ttf'), 40, 0xFFFFFFFF, "right", FlxTextBorderStyle.OUTLINE, 0xFF000000);
    skipText.alpha = 0;
    PS.currentStage.add(skipText);
    PS.isInCutscene = true;
    if (PS.camHUD != null) PS.camHUD.visible = false;
  }

  function gooeyStressCutscene():Void {
    cutsceneTimerManager = new FlxTimerManager();
    new FlxTimer(cutsceneTimerManager).start(60/24, _ -> {
      gooeyCutSound = PSSound.load(PSPaths.sound('stressGooeyCutscene/lines/2'), 1.0, false);
      gooeyCutSound.play(false);
    });
    new FlxTimer(cutsceneTimerManager).start(635/24, _ -> {
      finalizeGooeyCutscene();
      PSPlayState.instance.startCountdown();
    });
  }

  function finalizeGooeyCutscene():Void {
    var PS = PSPlayState.instance;
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
    var PS = PSPlayState.instance;
    if (PS.currentVariation != 'gooey') return;
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
    var PS = PSPlayState.instance;
    cutsceneTimerManager = new FlxTimerManager();
    PS.isInCutscene = true;
    if (PS.camHUD != null) PS.camHUD.visible = false;
    tankmanEnding = makeSparrowSprite('characters/TankmanEndingSprite');
    PS.currentStage.add(tankmanEnding);
    new FlxTimer(cutsceneTimerManager).start(320/24, _ -> {
      PS.endSong(true);
    });
  }

  // ── Helpers ────────────────────────────────
  static function makeSparrowSprite(id:String):FlxSprite {
    var s = new FlxSprite();
    s.frames = PSPaths.getSparrowAtlas(id);
    return s;
  }

  public static function register():StressSongPSlice {
    var b = new StressSongPSlice();
    return b;
  }
}

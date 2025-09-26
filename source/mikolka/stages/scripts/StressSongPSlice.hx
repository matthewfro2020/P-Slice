package mikolka.stages.scripts;

// P‑Slice port of the Funkin' (FNF-4/FNF Main) StressSong logic.
// - Removes direct Funkin engine dependencies and replaces them with P‑Slice equivalents.
// - Keep all variables and timings as close to the original as possible.
// - Plug this into your P‑Slice song bootstrap (see register() at bottom).
//
// Notes
// • Replace asset path helpers (PSPaths.*) if your fork uses a different path API.
// • Replace PSPlayState/PSProgress/PSVideo with your engine’s singletons/utilities.
// • ScriptedFlxAtlasSprite → FlxSprite using Sparrow/XML atlases (kept as helpers below).
// • DropShadowScreenspace/DropShadowShader mapped to simple shader wrappers; comment out if not needed.

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

// ────────────────────────────────────────────────────────────────────────────────
// Engine-facing shims (rename/types to match your P‑Slice fork)
// ────────────────────────────────────────────────────────────────────────────────
class PSPlayState {
  public static var instance(default, never):PSPlayState;
  public var camGame:FlxCamera;
  public var camHUD:FlxCamera;
  public var camCutscene:FlxCamera;
  public var isInCutscene:Bool = false;
  public var justUnpaused:Bool = false;
  public var currentVariation:String = "default"; // e.g. "pico" or "gooey"
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

class PSProgress {
  public static function hasBeatenSong(songId:String, difficulty:String, variation:String):Bool return false;
}

class PSPaths {
  public static function sound(id:String, ?folder:String):String return id;
  public static function music(id:String, ?folder:String):String return id;
  public static function video(id:String):String return id;
  public static function font(id:String):String return id;
  public static function getSparrowAtlas(id:String):FlxAtlasFrames return FlxAtlasFrames.fromSparrow(BitmapData.fromFile(id+".png"), id+".xml");
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

// Minimal shader shims (comment out if you don’t use these effects)
class DropShadowScreenspace { public var baseBrightness:Int; public var baseHue:Int; public var baseContrast:Int; public var baseSaturation:Int; public var angle:Float; public var threshold:Float; }
class DropShadowShader { public var angle:Float; public var color:UInt; public var attachedSprite:FlxSprite; public function new(){} public function setAdjustColor(a:Int,b:Int,c:Int,d:Int):Void{} }

// ────────────────────────────────────────────────────────────────────────────────
// Main behavior: StressSongPSlice
// ────────────────────────────────────────────────────────────────────────────────
class StressSongPSlice {
  // Runtime flags/state
  var hasPlayedCutscene:Bool = false;
  var hasPlayedEndCutscene:Bool = false;
  var cutsceneSkipped:Bool = false;
  var canSkipCutscene:Bool = false;

  // Cutscene actors & helpers
  var tankmanEnding:FlxSprite; // replaces ScriptedFlxAtlasSprite
  var tankmanGooey:FlxSprite;  // replaces ScriptedFlxAtlasSprite
  var fakeTanks:FlxSprite;
  var fakeGooey:FlxSprite;

  var skipText:FlxText;
  var bgSprite:FlxSprite;

  var rimlightCamera:FlxCamera;
  var gooeyRimlightCamera:FlxCamera;
  var screenspaceRimlight:DropShadowScreenspace = new DropShadowScreenspace();
  var screenspaceGooeyRimlight:DropShadowScreenspace = new DropShadowScreenspace();

  var cutsceneTimerManager:FlxTimerManager;
  var cutsceneMusic:PSSound;
  var gooeyCutSound:PSSound;

  public var songId:String = "stress"; // keep original id

  public function new() {}

  // ── Lifecycle hooks (wire these in your P‑Slice song loader) ────────────────
  public function onCreate():Void {
    hasPlayedCutscene = false;
    hasPlayedEndCutscene = false;
    cutsceneSkipped = false;
    canSkipCutscene = false;
  }

  public function onRetry():Void {
    hasPlayedCutscene = true; // don’t replay intro on retry
  }

  public function onCountdownStart():Void {
    var PS = PSPlayState.instance;

    // Gooey variant custom intro cutscene
    if (PS.currentVariation == 'gooey' && !hasPlayedCutscene) {
      preloadGooeyStressCutscene();
      if (PS.currentStage.getGirlfriend() != null) PS.currentStage.getGirlfriend().playAnimation('tankFrozen', true, true);
      gooeyStressCutscene();
      return; // countdown will be started at the end of cutscene
    }

    // Skip the vanilla video unless Story Mode/Pico Mix (mirrors original intent)
    var isPico = (PS.currentVariation == 'pico');
    if (!isPico /* && !PSPlaylist.isStoryMode (hook if you track Story/Freeplay) */) hasPlayedCutscene = true;

    if (!hasPlayedCutscene) {
      hasPlayedCutscene = true;
      startVideo(isPico);
    }
  }

  public function onUpdate(elapsed:Float):Void {
    var PS = PSPlayState.instance;

    if (PS.controls.CUTSCENE_ADVANCE && !cutsceneSkipped && PS.currentVariation == 'gooey') {
      if (!canSkipCutscene) {
        if (skipText != null) FlxTween.tween(skipText, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
        new FlxTimer().start(0.5, _ -> canSkipCutscene = true);
      } else {
        skipCutscene();
      }
    }

    if (PS.isInCutscene) {
      if (cutsceneTimerManager != null) cutsceneTimerManager.update(elapsed);
      if (rimlightCamera != null) syncRimCam(rimlightCamera);
      if (PS.currentVariation == 'gooey' && gooeyRimlightCamera != null) syncRimCam(gooeyRimlightCamera);
    }
  }

  public function onSongEndRequest():Bool {
    // Return true to intercept end (to play end cutscene), else false to let engine end song.
    var PS = PSPlayState.instance;
    if (PS.currentVariation == 'pico') return false; // no end cutscene override on pico
    if (hasPlayedEndCutscene) { hasPlayedEndCutscene = false; return false; }

    hasPlayedEndCutscene = true;

    // Prepare black BG under the end cutscene video/anim
    bgSprite = new FlxSprite(0,0);
    bgSprite.makeGraphic(2000, 2500, 0xFF000000);
    bgSprite.cameras = [PS.camCutscene];
    bgSprite.scrollFactor.set();
    bgSprite.alpha = 0;
    PS.add(bgSprite);
    PS.refresh();

    startEndCutscene();
    return true; // we intercepted end; engine should wait
  }

  // ── Video ──────────────────────────────────────────────────────────────────
  function startVideo(usePicoVideo:Bool):Void {
    var path = usePicoVideo ? 'stressPicoCutscene' : 'stressCutscene';
    // (Optional) If you support censor flag, append here.
    PSVideo.play(PSPaths.video(path));
  }

  // ── Gooey Intro Cutscene ───────────────────────────────────────────────────
  function preloadGooeyStressCutscene():Void {
    var PS = PSPlayState.instance;

    gooeyCutSound = PSSound.load(PSPaths.sound('stressGooeyCutscene/lines/1'), 1.0, false);
    if (PS.currentStage.getGirlfriend() != null) PS.currentStage.getGirlfriend().playAnimation('tankFrozen', true, true);

    // Skip text UI
    skipText = new FlxText(936, 618, 0, 'Skip [ ' + PS.controls.getDialogueNameFromToken("CUTSCENE_ADVANCE", true) + ' ]', 20);
    skipText.setFormat(PSPaths.font('vcr.ttf'), 40, 0xFFFFFFFF, "right", FlxTextBorderStyle.OUTLINE, 0xFF000000);
    skipText.scrollFactor.set();
    skipText.borderSize = 2;
    skipText.alpha = 0;
    PS.currentStage.add(skipText);
    skipText.cameras = [PS.camCutscene];

    // Tankman Gooey cutscene sprite (Sparrow)
    tankmanGooey = makeSparrowSprite('characters/TankmanGooeyStress');
    tankmanGooey.setPosition(PS.currentStage.getDad().x + 200, PS.currentStage.getDad().y + 230);
    PS.currentStage.add(tankmanGooey);
    tankmanGooey.zIndex = 101;

    // Rimlight cam
    gooeyRimlightCamera = new FlxCamera();
    FlxG.cameras.insert(gooeyRimlightCamera, -2, false);
    gooeyRimlightCamera.bgColor = 0x00FFFFFF;
    var gooFilter = new ShaderFilter(new DropShadowScreenspace());
    gooeyRimlightCamera.filters = [gooFilter];
    tankmanGooey.cameras = [gooeyRimlightCamera];

    // Fake stand-ins for timing reveals
    fakeTanks = makeSparrowSprite('characters/KamSpeaker');
    addSingleAnim(fakeTanks, 'tankFrozen', 'tankFrozen', 1, false, true);
    PS.currentStage.add(fakeTanks);
    fakeTanks.setPosition(PS.currentStage.getGirlfriend().x, PS.currentStage.getGirlfriend().y + 25);
    fakeTanks.zIndex = 99;

    fakeGooey = makeSparrowSprite('characters/Gooey');
    addSingleAnim(fakeGooey, 'idle', 'idle', 12, false, true);
    PS.currentStage.add(fakeGooey);
    fakeGooey.setPosition(PS.currentStage.getBoyfriend().x - 15, PS.currentStage.getBoyfriend().y + 40);
    fakeGooey.zIndex = 110;

    // (Optional) attach rim shaders to fakes
    PS.isInCutscene = true;
    if (PS.camHUD != null) PS.camHUD.visible = false;

    if (PS.currentStage.getGirlfriend() != null) PS.currentStage.getGirlfriend().visible = false;
    if (PS.currentStage.getBoyfriend() != null) PS.currentStage.getBoyfriend().visible = false;
    if (PS.currentStage.getDad() != null) PS.currentStage.getDad().visible = false;
  }

  function gooeyStressCutscene():Void {
    var PS = PSPlayState.instance;
    if (PS.currentVariation != 'gooey') return;

    var gooeyPos = [PS.currentStage.getBoyfriend().cameraFocusPoint.x, PS.currentStage.getBoyfriend().cameraFocusPoint.y];
    var kamPos   = [PS.currentStage.getGirlfriend().cameraFocusPoint.x, PS.currentStage.getGirlfriend().cameraFocusPoint.y];
    var tankPos  = [PS.currentStage.getDad().cameraFocusPoint.x,        PS.currentStage.getDad().cameraFocusPoint.y];

    cutsceneTimerManager = new FlxTimerManager();

    new FlxTimer(cutsceneTimerManager).start(0/24, _ -> {
      cutsceneMusic = PSSound.load(PSPaths.music('cutscene/cutscene', 'week7'), 1.0, true);
      cutsceneMusic.play(false);
      PS.tweenCameraToPosition(tankPos[0], tankPos[1], 2, FlxEase.smoothStepInOut);
      // play tankmanGooey anim here if needed
    });

    new FlxTimer(cutsceneTimerManager).start(6.5/24, _ -> gooeyCutSound.play(false));

    new FlxTimer(cutsceneTimerManager).start(60/24, _ -> {
      gooeyCutSound = PSSound.load(PSPaths.sound('stressGooeyCutscene/lines/2'), 1.0, false);
      gooeyCutSound.play(false);
    });

    new FlxTimer(cutsceneTimerManager).start(93/24, _ -> PS.tweenCameraZoom(0.71, 1, true, FlxEase.expoOut));
    new FlxTimer(cutsceneTimerManager).start(135/24, _ -> PS.tweenCameraZoom(0.70, 5, true, FlxEase.expoOut));
    new FlxTimer(cutsceneTimerManager).start(269/24, _ -> PS.tweenCameraZoom(0.71, 1, true, FlxEase.expoOut));
    new FlxTimer(cutsceneTimerManager).start(301/24, _ -> PS.tweenCameraZoom(0.72, 1, true, FlxEase.expoOut));

    new FlxTimer(cutsceneTimerManager).start(311/24, _ -> {
      PS.tweenCameraToPosition(kamPos[0] + 120, kamPos[1] + 200, 1.5, FlxEase.expoOut);
      PS.tweenCameraZoom(0.9, 2.6, true, FlxEase.smoothStepInOut);
    });

    new FlxTimer(cutsceneTimerManager).start(332/24, _ -> {
      var gf = PS.currentStage.getGirlfriend();
      var bf = PS.currentStage.getBoyfriend();
      if (gf != null) { gf.visible = true; gf.playAnimation('tankAim', true); }
      if (bf != null) { bf.visible = true; bf.playAnimation('ruhRohRaggy', true); }
      if (fakeTanks != null) fakeTanks.visible = false;
      if (fakeGooey != null) fakeGooey.visible = false;
      gooeyCutSound = PSSound.load(PSPaths.sound('stressGooeyCutscene/gockCockStress'), 1.0, false);
      gooeyCutSound.play(false);
    });

    new FlxTimer(cutsceneTimerManager).start(350/24, _ -> PS.currentStage.getBoyfriend().playAnimation('crystalGlow', true));

    new FlxTimer(cutsceneTimerManager).start(371/24, _ -> {
      PS.tweenCameraZoom(0.8, 0.5, true, FlxEase.expoOut);
      PS.tweenCameraToPosition(kamPos[0] + 80, kamPos[1] + 120, 1, FlxEase.expoOut);
      PS.currentStage.getGirlfriend().playAnimation('tankMurderSteve', true);
      PS.currentStage.getBoyfriend().playAnimation('omgFriend', true);
    });

    new FlxTimer(cutsceneTimerManager).start(372/24, _ -> {
      gooeyCutSound = PSSound.load(PSPaths.sound('stressGooeyCutscene/kamMurder'), 1.0, false);
      gooeyCutSound.play(false);
    });

    new FlxTimer(cutsceneTimerManager).start(391/24, _ -> PS.currentStage.getGirlfriend().playAnimation('tankGrab', true));
    new FlxTimer(cutsceneTimerManager).start(401/24, _ -> PS.currentStage.getGirlfriend().playAnimation('chokeLoop', true));
    new FlxTimer(cutsceneTimerManager).start(431/24, _ -> PS.currentStage.getGirlfriend().playAnimation('tankDed', true));

    new FlxTimer(cutsceneTimerManager).start(446/24, _ -> {
      PS.currentStage.getGirlfriend().playAnimation('helmetGrab', true);
      PS.tweenCameraZoom(0.75, 0.5, true, FlxEase.expoOut);
      PS.tweenCameraToPosition(kamPos[0] + 200, kamPos[1] + 200, 1, FlxEase.expoOut);
    });

    new FlxTimer(cutsceneTimerManager).start(456/24, _ -> PS.currentStage.getGirlfriend().playAnimation('Throw', true));

    new FlxTimer(cutsceneTimerManager).start(460/24, _ -> {
      PS.tweenCameraToPosition(kamPos[0] + 375, kamPos[1] + 275, 1, FlxEase.expoOut);
      PS.tweenCameraZoom(0.9, 0.5, true, FlxEase.expoOut);
    });

    new FlxTimer(cutsceneTimerManager).start(461/24, _ -> PS.currentStage.getBoyfriend().playAnimation('chickenJockey', true));

    new FlxTimer(cutsceneTimerManager).start(480/24, _ -> {
      PS.tweenCameraToPosition(tankPos[0], tankPos[1], 3, FlxEase.smoothStepInOut);
      PS.tweenCameraZoom(0.8, 3, true, FlxEase.expoOut);
      gooeyCutSound = PSSound.load(PSPaths.sound('stressGooeyCutscene/lines/3'), 1.0, false);
      gooeyCutSound.play(false);
    });

    new FlxTimer(cutsceneTimerManager).start(545/24, _ -> { gooeyCutSound = PSSound.load(PSPaths.sound('stressGooeyCutscene/lines/4'), 1.0, false); gooeyCutSound.play(false); });
    new FlxTimer(cutsceneTimerManager).start(580/24, _ -> PS.tweenCameraZoom(0.81, 1, true, FlxEase.expoOut));
    new FlxTimer(cutsceneTimerManager).start(607/24, _ -> PS.tweenCameraZoom(0.83, 1, true, FlxEase.expoOut));

    new FlxTimer(cutsceneTimerManager).start(611/24, _ -> {
      PS.tweenCameraToPosition(tankPos[0], tankPos[1], 2, FlxEase.smoothStepInOut);
      PS.tweenCameraZoom(0.7, 1, true, FlxEase.smoothStepInOut);
    });

    new FlxTimer(cutsceneTimerManager).start(635/24, _ -> {
      finalizeGooeyCutscene();
      PS.startCountdown();
      new FlxTimer().start(1, _ -> { if (gooeyRimlightCamera != null) { FlxG.cameras.remove(gooeyRimlightCamera); gooeyRimlightCamera = null; } });
    });
  }

  function finalizeGooeyCutscene():Void {
    var PS = PSPlayState.instance;
    canSkipCutscene = false;
    hasPlayedCutscene = true;
    cutsceneSkipped = true;
    PS.isInCutscene = false;
    if (PS.camHUD != null) PS.camHUD.visible = true;
    if (PS.currentStage.getDad() != null) PS.currentStage.getDad().visible = true;
    if (cutsceneMusic != null) cutsceneMusic.stop();
    if (tankmanGooey != null) { PS.currentStage.remove(tankmanGooey); tankmanGooey.destroy(); tankmanGooey = null; }
    if (skipText != null) skipText.visible = false;
    if (fakeTanks != null) { PS.currentStage.remove(fakeTanks); fakeTanks.destroy(); fakeTanks = null; }
    if (fakeGooey != null) { PS.currentStage.remove(fakeGooey); fakeGooey.destroy(); fakeGooey = null; }
  }

  function skipCutscene():Void {
    var PS = PSPlayState.instance;
    if (PS.currentVariation != 'gooey') return;
    cutsceneSkipped = true;
    hasPlayedCutscene = true;

    if (cutsceneMusic != null) cutsceneMusic.fadeOut(0.5, 0);
    if (gooeyCutSound != null) gooeyCutSound.fadeOut(0.5, 0);

    new FlxTimer().start(0.5, _ -> {
      if (tankmanGooey != null) { PS.currentStage.remove(tankmanGooey); tankmanGooey.destroy(); tankmanGooey = null; }
      if (cutsceneTimerManager != null) cutsceneTimerManager.clear();
      if (cutsceneMusic != null) cutsceneMusic.stop();
      if (gooeyCutSound != null) gooeyCutSound.stop();

      PS.startCountdown();
      if (skipText != null) skipText.visible = false;

      if (fakeTanks != null) { PS.currentStage.remove(fakeTanks); fakeTanks.destroy(); fakeTanks = null; }
      if (fakeGooey != null) { PS.currentStage.remove(fakeGooey); fakeGooey.destroy(); fakeGooey = null; }

      var gf = PS.currentStage.getGirlfriend();
      var bf = PS.currentStage.getBoyfriend();
      var dad = PS.currentStage.getDad();
      if (gf != null) { gf.visible = true; gf.playAnimation('idle', true); }
      if (bf != null) { bf.visible = true; bf.playAnimation('idle', true); }
      if (dad != null) { dad.visible = true; dad.playAnimation('idle', true); }

      PS.justUnpaused = true;
    });

    new FlxTimer().start(1, _ -> { if (gooeyRimlightCamera != null) { FlxG.cameras.remove(gooeyRimlightCamera); gooeyRimlightCamera = null; } });
  }

  // ── End Cutscene ────────────────────────────────────────────────────────────
  function startEndCutscene():Void {
    var PS = PSPlayState.instance;

    var bfPos = [PS.currentStage.getBoyfriend().cameraFocusPoint.x, PS.currentStage.getBoyfriend().cameraFocusPoint.y];
    var gfPos = [PS.currentStage.getGirlfriend().cameraFocusPoint.x, PS.currentStage.getGirlfriend().cameraFocusPoint.y];
    var dadPos= [PS.currentStage.getDad().cameraFocusPoint.x,       PS.currentStage.getDad().cameraFocusPoint.y];

    cutsceneTimerManager = new FlxTimerManager();

    PS.isInCutscene = true;
    if (PS.camHUD != null) PS.camHUD.visible = false;

    rimlightCamera = new FlxCamera();
    FlxG.cameras.insert(rimlightCamera, -2, false);
    rimlightCamera.bgColor = 0x00FFFFFF;
    var rimFilter = new ShaderFilter(new DropShadowScreenspace());
    rimlightCamera.filters = [rimFilter];

    tankmanEnding = makeSparrowSprite('characters/TankmanEndingSprite');
    tankmanEnding.setPosition(PS.currentStage.getDad().x + 723, PS.currentStage.getDad().y + 145);

    PS.tweenCameraToPosition(dadPos[0] + 320, dadPos[1] - 70, 2.8, FlxEase.expoOut);
    PS.tweenCameraZoom(0.65, 2, true, FlxEase.expoOut);

    PS.currentStage.getDad().visible = false;
    PS.currentStage.add(tankmanEnding);
    tankmanEnding.cameras = [rimlightCamera];

    // play tankmanEnding anim via .animation (add in assets)

    new FlxTimer(cutsceneTimerManager).start(176/24, _ -> PS.currentStage.getBoyfriend().playAnimation('laughEnd', true));

    new FlxTimer(cutsceneTimerManager).start(270/24, _ -> {
      PS.tweenCameraToPosition(dadPos[0] + 320, dadPos[1] - 370, 2, FlxEase.quadInOut);
      FlxTween.tween(bgSprite, {alpha: 1}, 2);
    });

    new FlxTimer(cutsceneTimerManager).start(320/24, _ -> {
      if (rimlightCamera != null) { FlxG.cameras.remove(rimlightCamera); rimlightCamera = null; }
      // tell engine it can finish now
      PS.endSong(true);
    });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  inline function syncRimCam(cam:FlxCamera):Void {
    var PS = PSPlayState.instance;
    cam.focusOn(new FlxPoint(PS.camGame.viewLeft + PS.camGame.viewWidth/2, PS.camGame.viewTop + PS.camGame.viewHeight/2));
    cam.zoom = PS.camGame.zoom;
  }

  static function makeSparrowSprite(id:String):FlxSprite {
    var s = new FlxSprite();
    s.frames = PSPaths.getSparrowAtlas(id);
    return s;
  }

  static function addSingleAnim(s:FlxSprite, name:String, prefix:String, fps:Int, loop:Bool, finishFrame:Bool):Void {
    if (s.frames == null) return;
    s.animation.addByPrefix(name, prefix, fps, loop);
    s.animation.play(name);
    if (finishFrame && s.animation.curAnim != null) s.animation.curAnim.finish();
  }

  // ── Registration hook (call once for this song/variation) ───────────────────
  public static function register():StressSongPSlice {
    var b = new StressSongPSlice();
    // Your loader should store this instance and call its hooks at the right times:
    //  b.onCreate(); b.onCountdownStart(); ... onUpdate(elapsed) ... if (b.onSongEndRequest()) wait ...
    return b;
  }
}

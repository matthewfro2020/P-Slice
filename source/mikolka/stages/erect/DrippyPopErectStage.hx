package mikolka.stages.erect;

import mikolka.compatibility.VsliceOptions;
import shaders.AdjustColorShader;
import states.PlayState;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.FlxCamera;

import backend.BaseStage;

/**
 * DrippyPop Erect special stage.
 * Includes animated mist layers + shaders.
 */
class DrippyPopErectStage extends BaseStage
{
    var singDir:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];

    // Shaders
    var colorShaderBf:AdjustColorShader;
    var colorShaderDad:AdjustColorShader;
    var colorShaderGf:AdjustColorShader;

    // Mist layers
    var mist0:FlxBackdrop;
    var mist1:FlxBackdrop;
    var mist2:FlxBackdrop;

    var _timer:Float = 0;

    public function new()
    {
        super();
    }

    override function create()
    {
        super.create();

        // ── Static background props ───────────────────────────
        var alley:FlxSprite = new FlxSprite(-260, -650);
        alley.frames = Paths.getSparrowAtlas("drip/ngErect");
        alley.scrollFactor.set(1, 1);
        alley.zIndex = 50;
        add(alley);

        var drippers:FlxSprite = new FlxSprite(-50, -430);
        drippers.frames = Paths.getSparrowAtlas("drip/drippersErect");
        drippers.animation.addByPrefix("idle", "drippers", 12, true);
        drippers.animation.play("idle");
        drippers.scrollFactor.set(1, 1);
        drippers.zIndex = 60;
        add(drippers);

        var shading:FlxSprite = new FlxSprite(-260, -650);
        shading.frames = Paths.getSparrowAtlas("drip/erectShade");
        shading.scrollFactor.set(1, 1);
        shading.zIndex = 100;
        add(shading);

        // ── Shaders for characters ───────────────────────────
        colorShaderBf = new AdjustColorShader();
        colorShaderDad = new AdjustColorShader();
        colorShaderGf = new AdjustColorShader();

        for (shader in [colorShaderBf, colorShaderDad, colorShaderGf])
        {
            shader.brightness = -5;
            shader.hue = -26;
            shader.contrast = 0;
            shader.saturation = -12;
        }

        // ── Mist overlays ────────────────────────────────────
        mist0 = new FlxBackdrop(Paths.image('drip/mistBack'), 0x01);
        mist0.setPosition(-650, -700);
        mist0.scrollFactor.set(1.2, 1.2);
        mist0.zIndex = 200;
        mist0.color = 0xFF5c5c5c;
        mist0.alpha = 0.6;
        mist0.velocity.x = 172;
        add(mist0);

        mist1 = new FlxBackdrop(Paths.image('drip/mistBack'), 0x01);
        mist1.setPosition(-650, -700);
        mist1.scrollFactor.set(1.1, 1.1);
        mist1.zIndex = 51;
        mist1.color = 0xFF5c5c5c;
        mist1.alpha = 0.6;
        mist1.velocity.x = 150;
        add(mist1);

        mist2 = new FlxBackdrop(Paths.image('drip/mistMid'), 0x01);
        mist2.setPosition(-650, -700);
        mist2.scrollFactor.set(0.95, 0.95);
        mist2.zIndex = 202;
        mist2.color = 0xFF5c5c5c;
        mist2.alpha = 0.5;
        mist2.velocity.x = -50;
        mist2.scale.set(0.8, 0.8);
        add(mist2);
    }

    override function createPost()
    {
        super.createPost();

        // Character positions (P-Slice: set x/y directly, no cameraOffset)
        PlayState.instance.boyfriend.x = 1350;
        PlayState.instance.boyfriend.y = 320;
        PlayState.instance.boyfriend.zIndex = 80;

        PlayState.instance.dad.x = 700;
        PlayState.instance.dad.y = 250;
        PlayState.instance.dad.zIndex = 70;

        PlayState.instance.gf.x = 1030;
        PlayState.instance.gf.y = 363;
        PlayState.instance.gf.zIndex = 60;
    }

    // P-Slice expects FlxCamera here, not Float
    override function getDefaultCamera():FlxCamera
    {
        return FlxG.camera;
    }

    override function update(elapsed:Float):Void
    {
        super.update(elapsed);

        _timer += elapsed;
        mist0.y = 60 + (Math.sin(_timer * 0.35) * 70);
        mist1.y = -100 + (Math.sin(_timer * 0.3) * 80);
        mist2.y = -430 + (Math.sin(_timer * 0.3) * 70);

        var bf = PlayState.instance.boyfriend;
        var gf = PlayState.instance.gf;
        var dad = PlayState.instance.dad;

        if (bf != null && bf.shader == null)
        {
            bf.shader = colorShaderBf;
            if (gf != null) gf.shader = colorShaderGf;
            if (dad != null) dad.shader = colorShaderDad;
        }
    }

    override function beatHit()
    {
        super.beatHit();
        if (curBeat <= 283)
        {
            if (PlayState.instance.gf != null && PlayState.instance.gf.hasAnimation("idle-alt"))
                PlayState.instance.gf.playAnim("idle-alt", false);
        }
    }

    override function countdownTick(count:Countdown, num:Int)
    {
        super.countdownTick(count, num);
        if (PlayState.instance.gf != null && PlayState.instance.gf.hasAnimation("idle-alt"))
            PlayState.instance.gf.playAnim("idle-alt", false);
    }

    // Handles GF singing notes
    public function gfSing(dir:Int, miss:Bool = false, ?suffix:String = '')
    {
        var anim:String = 'sing' + singDir[dir];
        if (PlayState.instance.gf != null && PlayState.instance.gf.hasAnimation(anim))
            PlayState.instance.gf.playAnim(anim, true);
    }
}

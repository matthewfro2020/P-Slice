package mikolka.stages.erect;

import mikolka.compatibility.VsliceOptions;
import shaders.AdjustColorShader;
import states.PlayState;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;

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

        var PS = PlayState.instance;

        // Boyfriend
        PS.boyfriend.setPosition(1350, 320);
        PS.boyfriend.cameraOffset.set(-200, -100);
        PS.boyfriend.zIndex = 80;

        // Dad
        PS.dad.setPosition(700, 250);
        PS.dad.cameraOffset.set(200, -20);
        PS.dad.zIndex = 70;

        // GF
        PS.gf.setPosition(1030, 363);
        PS.gf.cameraOffset.set(0, 0);
        PS.gf.zIndex = 60;
    }

    override function getDefaultCamera():Float
    {
        return 0.9; // from stage JSON
    }

    override function update(elapsed:Float):Void
    {
        super.update(elapsed);

        _timer += elapsed;
        mist0.y = 60 + (Math.sin(_timer * 0.35) * 70);
        mist1.y = -100 + (Math.sin(_timer * 0.3) * 80);
        mist2.y = -430 + (Math.sin(_timer * 0.3) * 70);

        var PS = PlayState.instance;
        if (PS.boyfriend.shader == null)
        {
            PS.boyfriend.shader = colorShaderBf;
            PS.gf.shader = colorShaderGf;
            PS.dad.shader = colorShaderDad;
        }
    }

    override function beatHit()
    {
        super.beatHit();
        if (curBeat <= 283)
        {
            PlayState.instance.gf.playAnimation('idle-alt', false, false);
        }
    }

    override function countdownTick(count:Countdown, num:Int)
    {
        super.countdownTick(count, num);
        PlayState.instance.gf.playAnimation('idle-alt', false, false);
    }

    // Handles GF singing notes
    public function gfSing(dir:Int, miss:Bool = false, ?suffix:String = '')
    {
        var anim:String = 'sing' + singDir[dir];
        PlayState.instance.gf.playAnimation(anim, true, true);
    }
}

package objects;

import funkin.play.character.MultiSparrowCharacter;
import funkin.play.PlayState;
import flixel.FlxG;
import funkin.graphics.FunkinSprite;
import flixel.util.FlxSpriteUtil;
import funkin.graphics.shaders.AdjustColorShader;
import funkin.vis.dsp.SpectralAnalyzer;
import funkin.Highscore;
import funkin.play.notes.Strumline;

class FloraSpeakerCharacter extends MultiSparrowCharacter {
    public function new(isChristmas:Bool = false) {
        super(isChristmas ? "flora-speaker-christmas" : "flora-speaker");
        this.isChristmas = isChristmas;
    }

    var flora:FunkinSprite;
    var floraCombo:FunkinSprite;
    var visualizerFlora:FunkinSprite;
    var christmas:FunkinSprite;
    var colorShader:AdjustColorShader;
    var refershedLol:Bool = false;

    // viz stuff
    var defaultPoints = [0.5,0.5,0.5,0.5,0.5,0.5,0.5];
    var points = defaultPoints;
    var lineStyle:LineStyle;
    var curve = 0;
    var analyzer:SpectralAnalyzer;

    var comboFloraCheck:Bool = true;
    var isChristmas:Bool = false;

    function onCreate(event:ScriptEvent) {
        super.onCreate(event);

        if (isChristmas) {
            christmas = new FunkinSprite(0, 0).loadSparrow("characters/FloraChristmas");
            christmas.animation.addByPrefix("idle", "christmas", 12, false);
            christmas.animation.play("idle"); christmas.animation.curAnim.finish();
            PlayState.instance.currentStage.add(christmas);

            colorShader = new AdjustColorShader();
            colorShader.hue = 5;
            colorShader.saturation = 20;
            christmas.shader = colorShader;
        }

        flora = new FunkinSprite(0,0).loadSparrow("characters/FloraLights");
        flora.animation.addByPrefix("idle", "lightBop", 12, false);
        flora.animation.play("idle"); flora.animation.curAnim.finish();
        PlayState.instance.currentStage.add(flora);

        floraCombo = new FunkinSprite(1000, 700).loadSparrow("characters/FloraLights");
        floraCombo.animation.addByPrefix("50combo","50combo",24,false);
        floraCombo.animation.addByPrefix("200combo","200combo",24,false);
        floraCombo.animation.addByPrefix("lossCombo","lossCombo",24,false);
        floraCombo.animation.play("50combo"); floraCombo.animation.curAnim.finish();
        PlayState.instance.currentStage.add(floraCombo);
        floraCombo.visible = false;

        visualizerFlora = new FunkinSprite().makeGraphic(115,70);
        PlayState.instance.currentStage.add(visualizerFlora);

        floraCombo.animation.onFinish.add(function(animName:String) {
            if (animName == "50combo" || animName == "200combo" || animName == "lossCombo") {
                comboFloraCheck = true; // fixed
                flora.visible = true;
                visualizerFlora.visible = true;
                floraCombo.visible = false;
            }
        });
    }

    override function dance(force:Bool) {
        if (flora != null) flora.animation.play("idle", false);
        if (isChristmas && christmas != null) christmas.animation.play("idle", false);
        super.dance(force);
    }

    function onNoteHit(event:HitNoteScriptEvent) {
        if (!event.note.noteData.getMustHitNote(Strumline.KEY_COUNT)) return;

        if (Highscore.tallies.combo == 50 && comboFloraCheck) {
            comboFloraCheck = false;
            flora.visible = false;
            visualizerFlora.visible = false;
            floraCombo.visible = true;
            floraCombo.animation.play("50combo",true);
        }
        if (Highscore.tallies.combo == 200 && comboFloraCheck) {
            comboFloraCheck = false;
            flora.visible = false;
            visualizerFlora.visible = false;
            floraCombo.visible = true;
            floraCombo.animation.play("200combo",true);
        }
        if (Highscore.tallies.combo >= 70 && event.isComboBreak && comboFloraCheck) {
            comboFloraCheck = false;
            flora.visible = false;
            visualizerFlora.visible = false;
            floraCombo.visible = true;
            floraCombo.animation.play("lossCombo",true);
        }
        super.onNoteHit(event);
    }

    function onNoteMiss(event:NoteScriptEvent) {
        if (Highscore.tallies.combo >= 70 && comboFloraCheck) {
            comboFloraCheck = false;
            flora.visible = false;
            visualizerFlora.visible = false;
            floraCombo.visible = true;
            floraCombo.animation.play("lossCombo",true);
        }
        super.onNoteMiss(event);
    }

    function onSongStart(scriptEvent) {
        super.onSongStart(scriptEvent);
        analyzer = new SpectralAnalyzer(FlxG.sound.music._channel.__audioSource, 7, 0.1, 40);
        analyzer.fftN = 256;
    }

    function onCountdownStart(scriptEvent) {
        super.onCountdownStart(scriptEvent);
        analyzer = null;
    }

    function onUpdate(event:UpdateScriptEvent) {
        super.onUpdate(event);
        if (!refershedLol) {
            flora.x = this.x + 10;
            flora.y = this.y + 10;
            flora.zIndex = this.zIndex + 1;
            flora.blend = 0;

            if (isChristmas && christmas != null) {
                christmas.x = this.x + 10;
                christmas.y = this.y + 10;
                christmas.zIndex = this.zIndex + 3;
            }

            floraCombo.x = this.x + 10;
            floraCombo.y = this.y + 10;
            floraCombo.zIndex = this.zIndex + 2;
            floraCombo.blend = 0;

            visualizerFlora.x = this.x + 342;
            visualizerFlora.y = this.y + 172;
            visualizerFlora.zIndex = flora.zIndex + 1;
            PlayState.instance.currentStage.add(flora);
            PlayState.instance.currentStage.refresh();
            refershedLol = true;
        }

        lineStyle = FlxSpriteUtil.getDefaultLineStyle({
            thickness: 4,
            color: 0xFF6cfffa
        });
    }

    override public function draw() {
        if (analyzer != null) {
            points = [];
            var levels = analyzer.getLevels();
            for (i in 0...levels.length) {
                points.push(levels[i].value/2);
                points[points.length-1] += 0.5;
            }
            points.push(0.5);
        } else {
            points = defaultPoints;
        }

        lineStyle.color = 0x00000000;
        FlxSpriteUtil.fill(visualizerFlora, 0);
        FlxSpriteUtil.beginDraw(0xFF6cfffa, lineStyle);

        for (b in [0,1]) {
            var oldPointX = 0;
            var oldPointY = visualizerFlora.height*0.6;
            var oldI = 0.5;
            for (i in 0...points.length) {
                var x = (visualizerFlora.width/points.length)*(i+1);
                var y = visualizerFlora.height*(1-points[i]+0.1);
                FlxSpriteUtil.flashGfx.moveTo(oldPointX,oldPointY);

                var stupidCurveAxes = curve;
                if (oldI >= points[i]) stupidCurveAxes = 0;

                FlxSpriteUtil.flashGfx.curveTo(((oldPointX+x)/2)+stupidCurveAxes,((oldPointY+y)/2),x,y);

                if (b == 0) {
                    FlxSpriteUtil.flashGfx.lineTo(x,visualizerFlora.height);
                    FlxSpriteUtil.flashGfx.lineTo(oldPointX,visualizerFlora.height);
                }
                oldPointX = x;
                oldPointY = y;
                oldI = points[i];
            }

            FlxSpriteUtil.flashGfx.moveTo(0,0);

            lineStyle.color = 0xFF6cfffa;
            FlxSpriteUtil.setLineStyle(lineStyle);
            FlxSpriteUtil.flashGfx.beginFill(0x00000000,0);
        }

        FlxSpriteUtil.endDraw(visualizerFlora, null);
        super.draw();
    }
}

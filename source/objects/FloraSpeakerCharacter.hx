package objects;

import funkin.play.character.MultiSparrowCharacter;
import funkin.play.PlayState;
import flixel.FlxG;
import funkin.graphics.FunkinSprite;
import flixel.util.FlxSpriteUtil;
import funkin.vis.dsp.SpectralAnalyzer;
import funkin.Highscore;

class FloraSpeakerCharacter extends MultiSparrowCharacter {
    var flora:FunkinSprite;
    var floraCombo:FunkinSprite;
    var visualizerFlora:FunkinSprite;
    var refershedLol:Bool = false;

    // Viz stuff
    var defaultPoints:Array<Float> = [0.5,0.5,0.5,0.5,0.5,0.5,0.5];
    var points:Array<Float> = defaultPoints;
    var lineStyle:LineStyle;
    var curve:Int = 0;
    var analyzer:SpectralAnalyzer;

    var comboFloraCheck:Bool = true;

    public function new() {
        super('flora-speaker');
    }

    override function onCreate(event:ScriptEvent) {
        super.onCreate(event);

        flora = new FunkinSprite(1000, 700).loadSparrow('characters/FloraLights');
        flora.animation.addByPrefix('idle','lightBop',12,false);
        flora.animation.play('idle');
        flora.animation.curAnim.finish();
        PlayState.instance.currentStage.add(flora);

        floraCombo = new FunkinSprite(1000, 700).loadSparrow('characters/FloraLights');
        floraCombo.animation.addByPrefix('50combo','50combo',24,false);
        floraCombo.animation.addByPrefix('200combo','200combo',24,false);
        floraCombo.animation.addByPrefix('lossCombo','lossCombo',24,false);
        floraCombo.animation.play('50combo');
        floraCombo.animation.curAnim.finish();
        PlayState.instance.currentStage.add(floraCombo);
        floraCombo.visible = false;

        visualizerFlora = new FunkinSprite().makeGraphic(115,70);
        PlayState.instance.currentStage.add(visualizerFlora);

        floraCombo.animation.onFinish.add(function(animName:String) {
            if (animName == "50combo" || animName == "200combo" || animName == "lossCombo") {
                comboFloraCheck = true;
                flora.visible = true;
                visualizerFlora.visible = true;
                floraCombo.visible = false;
            }
        });
    }

    override function dance(force:Bool) {
        if (flora != null && comboFloraCheck) {
            flora.animation.play('idle',false);
        }
        super.dance(force);
    }

    function onNoteHit(event:HitNoteScriptEvent) {
        if (!event.note.noteData.getMustHitNote()) return;

        if (Highscore.tallies.combo == 50 && comboFloraCheck) {
            comboFloraCheck = false;
            flora.visible = false;
            visualizerFlora.visible = false;
            floraCombo.visible = true;
            floraCombo.animation.play('50combo',true);
        }

        if (Highscore.tallies.combo == 200 && comboFloraCheck) {
            comboFloraCheck = false;
            flora.visible = false;
            visualizerFlora.visible = false;
            floraCombo.visible = true;
            floraCombo.animation.play('200combo',true);
        }

        if (Highscore.tallies.combo >= 70 && event.isComboBreak && comboFloraCheck) {
            comboFloraCheck = false;
            flora.visible = false;
            visualizerFlora.visible = false;
            floraCombo.visible = true;
            floraCombo.animation.play('lossCombo',true);
        }

        super.onNoteHit(event);
    }

    function onNoteMiss(event:NoteScriptEvent) {
        if (Highscore.tallies.combo >= 70 && comboFloraCheck) {
            comboFloraCheck = false;
            flora.visible = false;
            visualizerFlora.visible = false;
            floraCombo.visible = true;
            floraCombo.animation.play('lossCombo',true);
        }
        super.onNoteMiss(event);
    }

    override function onSongStart(event:ScriptEvent) {
        super.onSongStart(event);
        analyzer = new SpectralAnalyzer(FlxG.sound.music._channel.__audioSource, 7, 0.1, 40);
        analyzer.fftN = 256;
    }

    override function onCountdownStart(event:CountdownScriptEvent) {
        super.onCountdownStart(event);
        analyzer = null;
    }

    override function onUpdate(event:UpdateScriptEvent) {
        super.onUpdate(event);

        if (!refershedLol) {
            flora.x = this.x + 10;
            flora.y = this.y + 30;
            flora.zIndex = this.zIndex + 1;

            floraCombo.x = this.x + 10;
            floraCombo.y = this.y + 30;
            floraCombo.zIndex = this.zIndex + 2;

            visualizerFlora.x = this.x + 342;
            visualizerFlora.y = this.y + 192;
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

    override function onBeatHit(event:SongTimeScriptEvent) {
        super.onBeatHit(event);
        if (comboFloraCheck && flora != null) {
            flora.animation.play('idle', true);
        }
    }

    override public function draw() {
        if (analyzer != null) {
            points = [];
            var levels = analyzer.getLevels();
            for (i in 0...levels.length) {
                points.push(levels[i].value / 2);
                points[points.length - 1] += 0.5;
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
            var oldPointY = visualizerFlora.height * 0.6;
            var oldI = 0.5;
            for (i in 0...points.length) {
                var x = (visualizerFlora.width / points.length) * (i + 1);
                var y = visualizerFlora.height * (1 - points[i] + 0.1);
                FlxSpriteUtil.flashGfx.moveTo(oldPointX, oldPointY);

                var stupidCurveAxes = curve;
                if (oldI >= points[i]) stupidCurveAxes = 0;

                FlxSpriteUtil.flashGfx.curveTo(((oldPointX + x) / 2) + stupidCurveAxes,
                    ((oldPointY + y) / 2), x, y);

                if (b == 0) {
                    FlxSpriteUtil.flashGfx.lineTo(x, visualizerFlora.height);
                    FlxSpriteUtil.flashGfx.lineTo(oldPointX, visualizerFlora.height);
                }

                oldPointX = x;
                oldPointY = y;
                oldI = points[i];
            }

            FlxSpriteUtil.flashGfx.moveTo(0, 0);
            lineStyle.color = 0xFF6cfffa;
            FlxSpriteUtil.setLineStyle(lineStyle);
            FlxSpriteUtil.flashGfx.beginFill(0x00000000, 0);
        }

        FlxSpriteUtil.endDraw(visualizerFlora, null);
        super.draw();
    }
}

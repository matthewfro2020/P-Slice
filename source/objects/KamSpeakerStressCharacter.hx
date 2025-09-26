import funkin.play.character.SparrowCharacter;
import funkin.play.PlayState;
import flixel.FlxG;
import flixel.util.FlxSort;
import funkin.Conductor;
import funkin.graphics.FunkinSprite;
import funkin.graphics.shaders.AdjustColorShader;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxSpriteUtil.LineStyle;
import funkin.vis.dsp.SpectralAnalyzer;
import funkin.Highscore;

class KamSpeakerStressCharacter extends SparrowCharacter {
	var shootTimes:Array<Float> = [];
	var shootDirs:Array<Int> = [];

	var flora:FunkinSprite;
	var floraCombo:FunkinSprite;
	var realFlora:FunkinSprite;
	var visualizerFlora:FunkinSprite;

	var refershedLol:Bool = false;
	var comboFloraCheck:Bool = true;

	var defaultPoints:Array<Float> = [0.5,0.5,0.5,0.5,0.5,0.5,0.5];
	var points:Array<Float> = defaultPoints;
	var lineStyle:LineStyle;
	var curve:Int = 0;
	var analyzer:SpectralAnalyzer;

	var adjustColor:AdjustColorShader;

	function new() {
		super('kam-speaker-stress');
		ignoreExclusionPref.push("shoot1");
		ignoreExclusionPref.push("shoot2");
		ignoreExclusionPref.push("shoot3");
		ignoreExclusionPref.push("shoot4");
	}

	override function onCreate(event:ScriptEvent):Void {
		super.onCreate(event);

		realFlora = new FunkinSprite(0,0).loadSparrow('characters/FloraSpeaker');
		realFlora.animation.addByPrefix('idle','floraBop',12,false);
		realFlora.animation.play('idle'); realFlora.animation.curAnim.finish();
		PlayState.instance.currentStage.add(realFlora);

		adjustColor = new AdjustColorShader();
		adjustColor.hue = -10;
		adjustColor.saturation = -20;
		adjustColor.brightness = -30;
		adjustColor.contrast = -25;
		realFlora.shader = adjustColor;

		this.playAnimation('idle', true, true);

		initTimemap();

		flora = new FunkinSprite(0,0).loadSparrow('characters/FloraLights');
		flora.animation.addByPrefix('idle','lightBop',12,false);
		flora.animation.play('idle'); flora.animation.curAnim.finish();
		PlayState.instance.currentStage.add(flora);

		floraCombo = new FunkinSprite(1000, 700).loadSparrow('characters/FloraLights');
		floraCombo.animation.addByPrefix('50combo','50combo',24,false);
		floraCombo.animation.addByPrefix('200combo','200combo',24,false);
		floraCombo.animation.addByPrefix('lossCombo','lossCombo',24,false);
		floraCombo.animation.play('50combo'); floraCombo.animation.curAnim.finish();
		PlayState.instance.currentStage.add(floraCombo);
		floraCombo.visible = false;

		visualizerFlora = new FunkinSprite().makeGraphic(115,70);
		PlayState.instance.currentStage.add(visualizerFlora);
		visualizerFlora.visible = false;

		floraCombo.animation.onFinish.add(function(animName:String) {
			if (animName == "50combo" || animName == "200combo" || animName == "lossCombo") {
				comboFloraCheck = true;
				if (flora != null) flora.visible = true;
				if (visualizerFlora != null) visualizerFlora.visible = true;
				if (floraCombo != null) floraCombo.visible = false;
			}
		});
	}

	override function dance(force:Bool) {
		if (realFlora != null) realFlora.animation.play('idle', true);
		if (flora != null) flora.animation.play('idle', true);
		super.dance(force);
	}

	function onNoteMiss(event:NoteScriptEvent) {
		if (Highscore.tallies.combo >= 70 && comboFloraCheck) {
			comboFloraCheck = false;
			if (flora != null) flora.visible = false;
			if (visualizerFlora != null) visualizerFlora.visible = false;
			if (floraCombo != null) {
				floraCombo.visible = true;
				floraCombo.animation.play('lossCombo', true);
			}
		}
		super.onNoteMiss(event);
	}

	function onNoteHit(event:HitNoteScriptEvent) {
		if (!event.note.noteData.getMustHitNote()) return;

		if (Highscore.tallies.combo == 50 && comboFloraCheck) {
			comboFloraCheck = false;
			if (flora != null) flora.visible = false;
			if (visualizerFlora != null) visualizerFlora.visible = false;
			if (floraCombo != null) {
				floraCombo.visible = true;
				floraCombo.animation.play('50combo', true);
			}
		}
		if (Highscore.tallies.combo == 200 && comboFloraCheck) {
			comboFloraCheck = false;
			if (flora != null) flora.visible = false;
			if (visualizerFlora != null) visualizerFlora.visible = false;
			if (floraCombo != null) {
				floraCombo.visible = true;
				floraCombo.animation.play('200combo', true);
			}
		}
		if (Highscore.tallies.combo >= 70 && event.isComboBreak && comboFloraCheck) {
			comboFloraCheck = false;
			if (flora != null) flora.visible = false;
			if (visualizerFlora != null) visualizerFlora.visible = false;
			if (floraCombo != null) {
				floraCombo.visible = true;
				floraCombo.animation.play('lossCombo', true);
			}
		}
		super.onNoteHit(event);
	}

	function reset():Void {
		initTimemap();
	}

	function initTimemap():Void {
		trace('Initializing Otis timings...');
		shootTimes = [];
		shootDirs = [];

		var animChart:SongDifficulty = PlayState.instance.currentSong.getDifficulty('picospeaker', PlayState.instance.currentVariation);
		if (animChart == null) {
			trace('Initializing Otis (speaker) failed; no `picospeaker` chart found for this song.');
			return;
		} else {
			trace('Initializing Otis (speaker); found `picospeaker` chart, continuing...');
		}

		var animNotes:Array<SongNoteData> = animChart.notes;
		animNotes.sort(function(a:SongNoteData, b:SongNoteData):Int {
			return FlxSort.byValues(FlxSort.ASCENDING, a.time, b.time);
		});

		for (note in animNotes) {
			shootTimes.push(note.time);
			shootDirs.push(note.data);
		}
	}

	function onBeatHit(event:SongTimeScriptEvent) {
		super.onBeatHit(event);
		if (event.beat == 0 && visualizerFlora != null) {
			visualizerFlora.visible = true;
		}
	}

	override function onUpdate(event:UpdateScriptEvent):Void {
		super.onUpdate(event);

		if (!refershedLol) {
			if (realFlora != null) {
				realFlora.x = this.x + 600 - 30;
				realFlora.y = this.y + 670 - 10;
				realFlora.zIndex = this.zIndex - 2;
			}

			if (flora != null) {
				flora.x = (realFlora != null ? realFlora.x : this.x) - 30;
				flora.y = (realFlora != null ? realFlora.y : this.y) - 10;
				flora.zIndex = (realFlora != null ? realFlora.zIndex : this.zIndex) + 1;
				flora.blend = 0;
			}

			if (visualizerFlora != null) {
				visualizerFlora.x = flora.x + 332;
				visualizerFlora.y = flora.y + 162;
				visualizerFlora.zIndex = flora.zIndex + 1;
			}

			if (floraCombo != null) {
				floraCombo.x = flora.x;
				floraCombo.y = flora.y;
				floraCombo.zIndex = (realFlora != null ? realFlora.zIndex : this.zIndex) + 2;
				floraCombo.blend = 0;
			}

			PlayState.instance.currentStage.refresh();
			refershedLol = true;
		}

		lineStyle = FlxSpriteUtil.getDefaultLineStyle({
			thickness: 4,
			color: 0xFF6cfffa
		});

		// Play scheduled shoot anims
		if (shootTimes.length > 0 && shootTimes[0] <= Conductor.instance.songPosition) {
			shootTimes.shift();
			var nextDir:Int = shootDirs.shift();
			playPicoAnimation(nextDir);
		}
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

	function playPicoAnimation(direction:Int):Void {
		switch (direction) {
			case 0: this.playAnimation('shoot1', true, true);
			case 1: this.playAnimation('shoot2', true, true);
			case 2: this.playAnimation('shoot3', true, true);
			case 3: this.playAnimation('shoot4', true, true);
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

				FlxSpriteUtil.flashGfx.curveTo(((oldPointX + x) / 2) + stupidCurveAxes, ((oldPointY + y) / 2), x, y);

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

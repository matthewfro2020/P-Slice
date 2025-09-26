package mikolka.stages.erect;

import mikolka.vslice.StickerSubState;
import mikolka.stages.objects.TankmenBG;
#if !LEGACY_PSYCH
import cutscenes.CutsceneHandler;
import objects.Character;
import substates.GameOverSubstate;
#end
import mikolka.stages.cutscenes.VideoCutscene;
import mikolka.stages.cutscenes.PicoTankman;
import mikolka.stages.scripts.PicoCapableStage;
import mikolka.compatibility.VsliceOptions;
import shaders.DropShadowShader;
import mikolka.stages.scripts.StressSongPSlice;

class TankErect extends BaseStage {
	var sniper:FlxSprite;
	var guy:FlxSprite;
	var tankmanRun:FlxTypedGroup<TankmenBG>;
	var cutscene:PicoTankman;
	var pico_stage:PicoCapableStage;
	var stressSong:StressSongPSlice;
	var cutsceneSkipped:Bool = false;

	public function new() {
		if (songName == "stress-(pico-mix)")
			pico_stage = new PicoCapableStage(true);
		super();

		if (songName.toLowerCase().contains("stress")) {
			stressSong = StressSongPSlice.register();
			if (stressSong != null)
				stressSong.onCreate();
		}
	}

	override function create() {
		super.create();

		var bg:BGSprite = new BGSprite('erect/bg', -985, -805, 1, 1);
		bg.scale.set(1.15, 1.15);
		add(bg);

		sniper = new FlxSprite(-346, 245);
		sniper.frames = Paths.getSparrowAtlas('erect/sniper');
		sniper.animation.addByPrefix("idle", "Tankmanidlebaked instance 1", 24);
		sniper.animation.addByPrefix("sip", "tanksippingBaked instance 1", 24);
		sniper.scale.set(1.15, 1.15);
		add(sniper);

		guy = new FlxSprite(1175, 270);
		guy.frames = Paths.getSparrowAtlas('erect/guy');
		guy.animation.addByPrefix("idle", "BLTank2 instance 1", 24);
		guy.scale.set(1.15, 1.15);
		add(guy);

		tankmanRun = new FlxTypedGroup<TankmenBG>();
		add(tankmanRun);

		if (PicoCapableStage.instance != null)
			PicoCapableStage.instance.onABotInit.addOnce((pico) -> {
				applyAbotShader(pico.abot.speaker);
				applyShader(pico.abot.bg, "");
			});

		if (songName == "stress-(pico-mix)") {
			pico_stage.create();
			game.stages.remove(pico_stage);
			game.stages.insert(1, pico_stage);
			StickerSubState.STICKER_SET = "stickers-set-2";
			this.cutscene = new PicoTankman(this);
			if (!seenCutscene)
				setStartCallback(VideoCutscene.playVideo.bind('stressPicoCutscene', startCountdown));
			setEndCallback(cutscene.playCutscene);
		}

		if (songName == "stress-(gooey-mix)") {
			if (stressSong != null)
				stressSong.onCountdownStart();
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (songName == "stress-(gooey-mix)" && stressSong != null) {
			stressSong.onUpdate(elapsed);

			if (!cutsceneSkipped && PlayState.instance.controls.CUTSCENE_ADVANCE) {
				cutsceneSkipped = true;
				stressSong.skipCutscene();
			}
		}
	}

	override function beatHit() {
		super.beatHit();
		if (curBeat % 2 == 0) {
			sniper.animation.play('idle', true);
			guy.animation.play('idle', true);
		}
		if (FlxG.random.bool(2))
			sniper.animation.play('sip', true);
	}

	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float) {
		if (eventName == "Change Character" && VsliceOptions.SHADERS) {
			switch (value1.toLowerCase().trim()) {
				case 'gf' | 'girlfriend' | '2':
					applyShader(gf, gf.curCharacter);
				case 'dad' | 'opponent' | '1':
					applyShader(dad, dad.curCharacter);
				default:
					applyShader(boyfriend, boyfriend.curCharacter);
			}
		}
	}

	override function createPost() {
		if (VsliceOptions.SHADERS) {
			applyShader(boyfriend, boyfriend.curCharacter);
			applyShader(gf, gf.curCharacter);
			applyShader(dad, dad.curCharacter);
		}
		if (!VsliceOptions.LOW_QUALITY) {
			var bricks:BGSprite = new BGSprite('erect/bricksGround', 375, 640, 1, 1);
			bricks.scale.set(1.15, 1.15);
			add(bricks);

			for (daGf in gfGroup) {
				var gf:Character = cast daGf;
				if (gf.curCharacter == 'otis-speaker') {
					GameOverSubstate.characterName = 'pico-holding-nene-dead';
					var firstTank:TankmenBG = new TankmenBG(20, 500, true);
					firstTank.resetShit(20, 1500, true, false);
					firstTank.strumTime = 10;
					firstTank.visible = false;
					tankmanRun.add(firstTank);

					for (i in 0...TankmenBG.animationNotes.length) {
						if (FlxG.random.bool(16)) {
							var tankBih = tankmanRun.recycle(TankmenBG);
							if (VsliceOptions.SHADERS)
								applyShader(tankBih, "");
							tankBih.strumTime = TankmenBG.animationNotes[i][0];
							tankBih.scale.set(1, 1);
							tankBih.updateHitbox();
							tankBih.resetShit(500, 150, TankmenBG.animationNotes[i][1] < 2, false);
							tankmanRun.add(tankBih);
						}
					}
					break;
				}
			}
		}

		if (cutscene != null) {
			cutscene.preloadCutscene();
		}
	}

	override function endSong():Bool {
		if (songName == "stress-(gooey-mix)") {
			if (stressSong != null && stressSong.onSongEndRequest()) {
				return true;
			}
		}
		return super.endSong();
	}

	override function onGameOver():Void {
		super.onGameOver();

		if (songName == "stress-(gooey-mix)") {
			if (stressSong != null) {
				stressSong.onRetry();
			}
		}
	}

	// ── Shaders ──────────────────────────────────────────────
	function applyAbotShader(sprite:FlxSprite) {
		var rim = new DropShadowShader();
		rim.setAdjustColor(-46, -38, -25, -20);
		rim.color = 0xFFDFEF3C;
		rim.antialiasAmt = 0;
		rim.attachedSprite = sprite;
		rim.distance = 5;
		rim.angle = 90;

		sprite.shader = rim;

		// ✅ Single callback at the end
		sprite.animation.callback = function(anim, frame, index) {
			rim.updateFrameInfo(sprite.frame);
		};
	}

	function applyShader(sprite:FlxSprite, char_name:String) {
		var rim = new DropShadowShader();
		rim.setAdjustColor(-46, -38, -25, -20);
		rim.color = 0xFFDFEF3C;
		rim.threshold = 0.3;
		rim.attachedSprite = sprite;
		rim.distance = 15;
		rim.strength = 1;
		rim.angle = 90;

		switch (char_name) {
			case "bf":
				rim.threshold = 0.1;

			case "gf-tankmen":
				rim.setAdjustColor(-42, -10, 5, -25);
				rim.distance = 3;
				rim.threshold = 0.1;
				rim.altMaskImage = Paths.image("erect/masks/gfTankmen_mask").bitmap;
				rim.maskThreshold = 1;
				rim.useAltMask = true;

			case "tankman-bloody":
				rim.angle = 135;
				rim.altMaskImage = Paths.image("erect/masks/tankmanCaptainBloody_mask").bitmap;
				rim.maskThreshold = 1;
				rim.threshold = 0.1;
				rim.useAltMask = true;

			case "tankman":
				rim.angle = 135;
				rim.threshold = 0.1;
				rim.maskThreshold = 1;
				rim.useAltMask = false;

			case "nene":
				rim.threshold = 0.1;
				rim.angle = 90;

			default:
				rim.angle = 90;
		}

		sprite.shader = rim;
		// ✅ Only one callback at the end
		sprite.animation.callback = function(anim, frame, index) {
			rim.updateFrameInfo(sprite.frame);
		};
	}
}

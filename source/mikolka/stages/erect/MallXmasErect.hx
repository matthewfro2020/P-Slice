package mikolka.stages.erect;

import mikolka.stages.scripts.PicoCapableStage;
import shaders.AdjustColorShader;
import mikolka.compatibility.VsliceOptions;
#if !LEGACY_PSYCH
import substates.GameOverSubstate;
#end

// Corrected imports
import objects.BGSprite;
import states.stages.objects.MallCrowd;
import objects.FloraSpeakerCharacter;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;

class MallXmasErect extends BaseStage {
	var upperBoppers:BGSprite;
	var bottomBoppers:MallCrowd;
	var santa:BGSprite;

	var erectSanta:FlxAtlasSprite;
	var erectParents:FlxAtlasSprite;

	// Flora
	var flora:FloraSpeakerCharacter;

	override function create() {
		var _song = PlayState.SONG;

		var bg:BGSprite = new BGSprite('christmas/erect/bgWalls', -726, -566, 0.2, 0.2);
		bg.setGraphicSize(Std.int(bg.width * 0.9));
		bg.updateHitbox();
		add(bg);

		if (!VsliceOptions.LOW_QUALITY) {
			upperBoppers = new BGSprite('christmas/erect/upperBop', -374, -98, 0.28, 0.28, ['upperBop']);
			upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
			upperBoppers.updateHitbox();
			add(upperBoppers);

			var bgEscalator:BGSprite = new BGSprite('christmas/erect/bgEscalator', -1100, -540, 0.3, 0.3);
			bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
			bgEscalator.updateHitbox();
			add(bgEscalator);
		}

		var tree:BGSprite = new BGSprite('christmas/erect/christmasTree', 370, -250, 0.40, 0.40);
		add(tree);

		var fog = new BGSprite("christmas/erect/white", -1000, 100, 0.85, 0.85);
		fog.scale.set(0.9, 0.9);
		add(fog);

		bottomBoppers = new MallCrowd(-300, 140, 'christmas/erect/bottomBop', "bottomBop");
		add(bottomBoppers);

		var fgSnow:BGSprite = new BGSprite('christmas/erect/fgSnow', -880, 700);
		add(fgSnow);

		santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
		add(santa);
		setDefaultGF('gf-christmas');

		if (songName == "eggnog-(gooey-mix)") {
			flora = new FloraSpeakerCharacter(600, 350, false);
			add(flora);
		}

		if (songName == "eggnog-erect" || songName == "eggnog-(pico-mix)") {
			erectSanta = new FlxAtlasSprite(-840 + 380, 150 + 347, "christmas/santa_speaks_assets");
			erectParents = new FlxAtlasSprite(100 - 620, 100 + 401, "christmas/parents_shoot_assets");
			setEndCallback(eggnogEndCutscene);
		}
	}

	override function createPost() {
		super.createPost();
		if (VsliceOptions.SHADERS) {
			var colorShader = new AdjustColorShader();
			colorShader.hue = 5;
			colorShader.saturation = 20;

			boyfriend.shader = colorShader;
			gf.shader = colorShader;
			dad.shader = colorShader;
			santa.shader = colorShader;
			if (flora != null) flora.shader = colorShader; // 🌟 safe shader
			if (erectSanta != null) {
				erectSanta.shader = santa.shader;
				erectParents.shader = santa.shader;
			}
			if (PicoCapableStage.instance != null)
				PicoCapableStage.instance.applyABotShader(colorShader);
		}

		@:privateAccess
		if (PicoCapableStage.NENE_LIST.contains(PlayState.SONG.gfVersion))
			GameOverSubstate.characterName = 'pico-christmas-dead';
	}

	override function countdownTick(count:Countdown, num:Int)
		everyoneDance();

	override function beatHit() {
		super.beatHit();
		everyoneDance();
	}

	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float) {
		switch (eventName) {
			case "Hey!":
				switch (value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						return;
				}
				bottomBoppers.animation.play('hey', true);
				bottomBoppers.heyTimer = flValue2;
		}
	}

	function everyoneDance() {
		if (!VsliceOptions.LOW_QUALITY)
			upperBoppers.dance();

		bottomBoppers.dance();
		santa.dance();
		if (flora != null) flora.dance();
	}

	function eggnogEndCutscene() {
		remove(santa);
		dad.visible = false;
		canPause = false;
		game.endingSong = true;
		add(erectParents);
		add(erectSanta);

		erectSanta.playAnimation("santa whole scene", false, false, false, 0);
		erectParents.playAnimation("parents whole scene", false, false, false, 0);
		FlxG.sound.play(Paths.sound("santa_emotion"));
		erectSanta.onAnimationComplete.add(s -> erectSanta.anim.pause());
		erectParents.onAnimationComplete.add(s -> erectParents.anim.pause());

		new FlxTimer().start(2.8, function(tmr) {
			camFollow_set(erectSanta.x + 150, erectSanta.y);
			FlxTween.tween(camGame, {zoom: 0.79}, 9, { ease: FlxEase.quadInOut });
		});

		new FlxTimer().start(11.375, function(tmr) {
			FlxG.sound.play(Paths.sound('santa_shot_n_falls'));
		});

		new FlxTimer().start(12.83, function(tmr) {
			camGame.shake(0.005, 0.2);
			camFollow_set(erectSanta.x + 160, erectSanta.y + 80);
		});

		new FlxTimer().start(15, function(tmr) {
			camHUD.fade(0xFF000000, 1, false, null, true);
		});

		new FlxTimer().start(16, function(tmr) {
			camHUD.fade(0xFF000000, 0.5, true, null, true);
			endSong();
		});
	}
}

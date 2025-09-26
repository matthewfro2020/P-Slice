package mikolka.stages.erect;

import mikolka.stages.scripts.PicoCapableStage;
import mikolka.compatibility.VsliceOptions;

import backend.BaseStage;
import states.PlayState;
import substates.GameOverSubstate;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

import shaders.AdjustColorShader;

import mikolka.stages.objects.BGSprite;
import mikolka.stages.objects.MallCrowd;
import objects.FloraSpeakerCharacter;

/**
 * Special Week 5 Erect stage with Gooey/Pico/Normal variants.
 */
class MallXmasErect extends BaseStage {
	var upperBoppers:BGSprite;
	var bottomBoppers:MallCrowd;
	var santa:BGSprite;

	var erectSanta:FlxSprite;
	var erectParents:FlxSprite;

	// Flora cameo
	var flora:FloraSpeakerCharacter;

	override function create() {
		super.create();

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

		// Gooey cameo
		if (songName == "eggnog-(gooey-mix)") {
			flora = new FloraSpeakerCharacter(600, 350, false);
			add(flora);
		}

		// Pico/Erect mix cutscenes
		if (songName == "eggnog-erect" || songName == "eggnog-(pico-mix)") {
			erectSanta = new FlxSprite(-460, 497);
			erectSanta.frames = Paths.getSparrowAtlas("christmas/santa_speaks_assets");

			erectParents = new FlxSprite(-520, 501);
			erectParents.frames = Paths.getSparrowAtlas("christmas/parents_shoot_assets");

			setEndCallback(eggnogEndCutscene);
		}
	}

	override function createPost() {
		super.createPost();

		if (VsliceOptions.SHADERS) {
			var colorShader = new AdjustColorShader();
			colorShader.hue = 5;
			colorShader.saturation = 20;

			if (boyfriend != null) boyfriend.shader = colorShader;
			if (gf != null) gf.shader = colorShader;
			if (dad != null) dad.shader = colorShader;
			if (santa != null) santa.shader = colorShader;
			if (flora != null) flora.shader = colorShader;
			if (erectSanta != null) erectSanta.shader = colorShader;
			if (erectParents != null) erectParents.shader = colorShader;

			if (PicoCapableStage.instance != null)
				PicoCapableStage.instance.applyABotShader(colorShader);
		}

		if (PicoCapableStage.NENE_LIST.contains(PlayState.SONG.gfVersion))
			GameOverSubstate.characterName = 'pico-christmas-dead';
	}

	override function countdownTick(count:Countdown, num:Int) {
		everyoneDance();
	}

	override function beatHit() {
		super.beatHit();
		everyoneDance();
	}

	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float) {
		switch (eventName) {
			case "Hey!":
				bottomBoppers.animation.play('hey', true);
				bottomBoppers.heyTimer = flValue2;
		}
	}

	function everyoneDance() {
		if (!VsliceOptions.LOW_QUALITY && upperBoppers != null)
			upperBoppers.dance();

		if (bottomBoppers != null) bottomBoppers.dance();
		if (santa != null) santa.dance();
		if (flora != null) flora.dance();
	}

	function eggnogEndCutscene() {
		if (santa != null) remove(santa);
		if (dad != null) dad.visible = false;
		canPause = false;
		game.endingSong = true;

		if (erectParents != null) add(erectParents);
		if (erectSanta != null) add(erectSanta);

		if (erectSanta != null) erectSanta.animation.play("santa whole scene", true);
		if (erectParents != null) erectParents.animation.play("parents whole scene", true);

		FlxG.sound.play(Paths.sound("santa_emotion"));

		new FlxTimer().start(2.8, function(tmr) {
			camFollow_set(erectSanta.x + 150, erectSanta.y);
			FlxTween.tween(camGame, {zoom: 0.79}, 9, {ease: FlxEase.quadInOut});
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

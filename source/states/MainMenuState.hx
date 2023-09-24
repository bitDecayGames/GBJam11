package states;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import ui.Fader;
import input.SimpleController;
import flixel.util.FlxSpriteUtil;
import ui.font.BitmapText.TrooperLightest;
import flixel.FlxSprite;
import bitdecay.flixel.transitions.TransitionDirection;
import bitdecay.flixel.transitions.SwirlTransition;
import states.AchievementsState;
import com.bitdecay.analytics.Bitlytics;
import config.Configure;
import flixel.FlxG;
import flixel.addons.ui.FlxUICursor;
import flixel.addons.ui.FlxUIState;
import flixel.addons.ui.FlxUITypedButton;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import haxefmod.flixel.FmodFlxUtilities;

using states.FlxStateExt;

#if windows
import lime.system.System;
#end

class MainMenuState extends FlxUIState {
	var fade = new Fader();
	var pressStart:TrooperLightest;
	var handleInput = true;

	override public function create():Void {
		super.create();

		// FmodManager.PlaySong(FmodSongs.LetsGo);
		bgColor = Constants.DARKEST;
		FlxG.camera.pixelPerfectRender = true;

		// Trigger our focus logic as we are just creating the scene
		this.handleFocus();

		// we will handle transitions manually
		transOut = null;

		var bg = new FlxSprite(0, -100, AssetPaths.Title__png);
		add(bg);

		pressStart = new TrooperLightest("press start");
		pressStart.screenCenter(X);
		pressStart.y = -100;
		add(pressStart);

		add(fade);

		FlxTween.tween(bg, {y: 30}, {
			ease: FlxEase.expoIn,
			onComplete: (t) -> {
				camera.shake(0.03, 0.1);
				FlxTween.tween(pressStart, {y: FlxG.height - 30}, {
					ease: FlxEase.expoIn,
					onComplete: (t2) -> {
						camera.shake(0.03, 0.1);
						FlxSpriteUtil.flicker(pressStart, 0, 0.5);
						handleInput = true;
					}
				});
			}
		});
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		if (FlxG.keys.pressed.D && FlxG.keys.justPressed.M) {
			// Keys D.M. for Disable Metrics
			Bitlytics.Instance().EndSession(false);
			FmodManager.PlaySoundOneShot(FmodSFX.MenuSelect);
			trace("---------- Bitlytics Stopped ----------");
		}

		if (handleInput && SimpleController.just_pressed(START)) {
			handleInput = false;
			FlxSpriteUtil.flicker(pressStart, 0, 0.25);
			new FlxTimer().start(1, (t) -> {
				clickPlay();
			});
		}
	}

	function clickPlay():Void {
		FmodManager.StopSong();
		fade.fadeOut(() -> {
			FlxG.switchState(new PlayState());
		});
	}

	override public function onFocusLost() {
		super.onFocusLost();
		this.handleFocusLost();
	}

	override public function onFocus() {
		super.onFocus();
		this.handleFocus();
	}
}

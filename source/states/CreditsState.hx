package states;

import ui.font.BitmapText.TrooperWhite;
import com.bitdecay.analytics.Bitlytics;
import helpers.Analytics;
import progress.Collected;
import ui.font.BitmapText.Trooper;
import ui.Fader;
import flixel.util.FlxTimer;
import loaders.AsepriteMacros;
import loaders.Aseprite;
import input.SimpleController;
import flixel.text.FlxText.FlxTextAlign;
import flixel.text.FlxBitmapText;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUIState;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import haxefmod.flixel.FmodFlxUtilities;
import config.Configure;
import helpers.UiHelpers;
import misc.FlxTextFactory;

using states.FlxStateExt;

class CreditsState extends FlxUIState {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/Finale.json");

	var _allCreditElements:Array<FlxSprite>;

	var _btnMainMenu:FlxButton;

	var _txtCreditsTitle:FlxBitmapText;
	var _txtThankYou:FlxBitmapText;
	var _txtRole:Array<FlxBitmapText>;
	var _txtCreator:Array<FlxBitmapText>;
	var _txtDeathToll:FlxBitmapText;

	// Quick appearance variables
	private var backgroundColor = FlxColor.BLACK;

	static inline var entryLeftMargin = 50;
	static inline var entryRightMargin = 5;
	static inline var entryVerticalSpacing = 25;

	var baseScrollSpeed = 50;
	var doScroll = false;

	var toolingImages = [
		AssetPaths.FLStudioLogo__png,
		AssetPaths.FmodLogoBlack__png,
		AssetPaths.HaxeFlixelLogo__png,
		AssetPaths.pyxel_edit__png
	];

	var fader:Fader;

	override public function create():Void {
		super.create();

		#if credits
		Collected.initialize();
		#end

		fader = new Fader();
		bgColor = Constants.DARKEST;
		var bgImage = new FlxSprite();
		Aseprite.loadAllAnimations(bgImage, AssetPaths.Finale__json);
		add(bgImage);
		camera.pixelPerfectRender = true;

		bgImage.animation.finishCallback = (name) -> {
			if (name == anims.Escape) {
				bgImage.animation.play(anims.Credits);
			}
		};

		fader.fadeIn(() -> {
			new FlxTimer().start(0.5, (t) -> {
				bgImage.animation.play(anims.Escape);
				new FlxTimer().start(2, (t) -> {
					doScroll = true;
				});
			});
		});

		// Button

		// _btnMainMenu = UiHelpers.createMenuButton("Main Menu", clickMainMenu);
		// _btnMainMenu.setPosition(FlxG.width - _btnMainMenu.width, FlxG.height - _btnMainMenu.height);
		// _btnMainMenu.updateHitbox();
		// add(_btnMainMenu);

		// Credits

		_allCreditElements = new Array<FlxSprite>();

		_txtCreditsTitle = new TrooperWhite(FlxG.width / 4, FlxG.height / 2 + FlxG.height, "Credits");
		_txtCreditsTitle.color = Constants.DARK;
		_txtCreditsTitle.borderStyle = OUTLINE;
		_txtCreditsTitle.borderSize = 1;
		_txtCreditsTitle.borderColor = Constants.DARK_TO_DARKEST_MULT;
		center(_txtCreditsTitle);
		add(_txtCreditsTitle);

		_txtRole = new Array<FlxBitmapText>();
		_txtCreator = new Array<FlxBitmapText>();

		_allCreditElements.push(_txtCreditsTitle);

		for (entry in Configure.getCredits()) {
			AddSectionToCreditsTextArrays(entry.sectionName, entry.names, _txtRole, _txtCreator);
		}

		var creditsVerticalOffset = FlxG.height * 2;

		for (flxText in _txtRole) {
			flxText.setPosition(entryRightMargin, creditsVerticalOffset);
			creditsVerticalOffset += entryVerticalSpacing;
		}

		creditsVerticalOffset = FlxG.height * 2 + 16;

		for (flxText in _txtCreator) {
			flxText.setPosition(entryRightMargin, creditsVerticalOffset);
			creditsVerticalOffset += entryVerticalSpacing;
		}

		for (toolImg in toolingImages) {
			var display = new FlxSprite();
			display.loadGraphic(toolImg);
			// scale them to be about 1/4 of the height of the screen
			var scale = (FlxG.height / 4) / display.height;
			if (display.width * scale > FlxG.width) {
				// in case that's too wide, adjust accordingly
				scale = FlxG.width / display.width;
			}
			display.scale.set(scale, scale);
			display.updateHitbox();
			display.setPosition(0, creditsVerticalOffset);
			center(display);
			add(display);
			creditsVerticalOffset += Math.ceil(display.height) + entryVerticalSpacing;
			_allCreditElements.push(display);
		}

		_txtThankYou = new TrooperWhite(entryRightMargin, creditsVerticalOffset + FlxG.height / 2, "Thank you!");
		_txtThankYou.alignment = FlxTextAlign.LEFT;
		_txtThankYou.color = Constants.DARK;
		_txtThankYou.borderStyle = OUTLINE;
		_txtThankYou.borderSize = 1;
		_txtThankYou.borderColor = Constants.DARK_TO_DARKEST_MULT;
		add(_txtThankYou);
		_allCreditElements.push(_txtThankYou);

		_txtDeathToll = new TrooperWhite('Soldiers Lost: ${Collected.getDeathCount()}');
		_txtDeathToll.color = Constants.DARK;
		_txtDeathToll.borderStyle = OUTLINE;
		_txtDeathToll.borderSize = 1;
		_txtDeathToll.borderColor = Constants.DARK_TO_DARKEST_MULT;
		_txtDeathToll.screenCenter(X);
		_txtDeathToll.y = _txtThankYou.y + 35;
		add(_txtDeathToll);
		_allCreditElements.push(_txtDeathToll);

		add(fader);

		Analytics.reportWin(Collected.getDeathCount(), 0);
		Bitlytics.Instance().ForceFlush();
		Collected.gameComplete();
	}

	private function AddSectionToCreditsTextArrays(role:String, creators:Array<String>, finalRoleArray:Array<FlxBitmapText>,
			finalCreatorsArray:Array<FlxBitmapText>) {
		var roleText = new TrooperWhite(0, 0, role);
		roleText.color = Constants.DARK;
		roleText.alignment = LEFT;
		roleText.borderStyle = OUTLINE;
		roleText.borderSize = 1;
		roleText.borderColor = Constants.DARK_TO_DARKEST_MULT;
		add(roleText);
		finalRoleArray.push(roleText);
		_allCreditElements.push(roleText);

		if (finalCreatorsArray.length != 0) {
			finalCreatorsArray.push(new FlxBitmapText(" "));
		}

		for (creator in creators) {
			// Make an offset entry for the roles array
			finalRoleArray.push(new FlxBitmapText(" "));

			var creatorText = new TrooperWhite(0, 0, creator);
			creatorText.color = Constants.DARK;
			creatorText.alignment = LEFT;
			creatorText.borderStyle = OUTLINE;
			creatorText.borderSize = 1;
			creatorText.borderColor = Constants.DARK_TO_DARKEST_MULT;
			add(creatorText);
			finalCreatorsArray.push(creatorText);
			_allCreditElements.push(creatorText);
		}
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		if (!doScroll) {
			return;
		}

		// Stop scrolling when "Thank You" text is in the center of the screen
		if (_txtThankYou.y + _txtThankYou.height / 2 < FlxG.height / 2 + 10) {
			return;
		}

		for (element in _allCreditElements) {
			if (SimpleController.pressed(A)) {
				element.y -= 2 * baseScrollSpeed * elapsed;
			} else {
				element.y -= baseScrollSpeed * elapsed;
			}
		}
	}

	private function center(o:FlxObject) {
		o.x = (FlxG.width - o.width) / 2;
	}

	function clickMainMenu():Void {
		FmodFlxUtilities.TransitionToState(new MainMenuState());
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

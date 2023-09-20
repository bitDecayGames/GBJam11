package entities;

import flixel.util.FlxTimer;
import entities.projectile.BasicBullet;
import entities.Player.PlayerState;
import bitdecay.flixel.debug.DebugDraw;
import debug.DebugLayers;
import flixel.util.FlxColor;
import states.PlayState;
import echo.Line;
import echo.util.AABB;
import flixel.math.FlxPoint;
import echo.math.Vector2;
import echo.data.Data.CollisionData;
import entities.sensor.AlienSpawner;
import entities.sensor.Trigger;
import echo.Body;
import loaders.AsepriteMacros;
import loaders.Aseprite;
import animation.AnimationState;

using echo.FlxEcho;

class Alien extends BaseHumanoid {
	public static var anims = AsepriteMacros.tagNames("assets/aseprite/characters/alien.json");

	var source:AlienSpawner = null;

	var controlState:PlayerState = FALLING;

	public function new(x:Float, y:Float, source:AlienSpawner) {
		super(x, y);

		flipX = true;

		this.source = source;

		// This aligns the body's bottom edge with whatever coordinate y was passed in for our creation
		// body.y = body.y - (mainBody.bottom - mainBody.top)/2 - mainBody.get_local_position().y;
	}

	override function configSprite() {
		super.configSprite();

		// This call can be used once https://github.com/HaxeFlixel/flixel/pull/2860 is merged
		// FlxAsepriteUtil.loadAseAtlasAndTags(this, AssetPaths.player__png, AssetPaths.player__json);
		Aseprite.loadAllAnimations(this, AssetPaths.alien__json);
		animation.play(anims.Jump);
		animation.finishCallback = (name) -> {
			if (name == anims.Death) {
				kill();
			}
		};
		animation.callback = (anim, frame, index) -> {
			// if (eventData.exists(index)) {
				// trace('frame $index has data ${eventData.get(index)}');
			// }
		};
	}

	override function makeBody():Body {
		return this.add_body({
			x: x,
			y: y,
			shapes: [
				{
					type:RECT,
					width: 12,
					height: 20,
					offset_y: 3,
					// offset_x: -2
				}
			]
		});
	}

	override function handleEnter(other:Body, data:Array<CollisionData>) {
		super.handleEnter(other, data);

		if (other.object is BasicBullet) {
			animation.play(anims.Death);
			body.active = false;
		}

		if (data[0].normal.y > 0) {
			checkGrounded = true;
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (body.active) {
			updateBehavior(elapsed);
			updateCurrentAnimation();
		}
		
		updateGrounded();
	}

	var shotInterval = 1.5;
	var shotTimer  = 1.5;

	public function updateBehavior(delta:Float) {
		shotTimer -= delta;

		if (shotTimer <= 0) {
			shotTimer = shotInterval;

			handleShoot();
		}
	}

	override function updateCurrentAnimation() {
		var nextAnim = animation.curAnim.name;
		if (intentState.has(MOVE_RIGHT)) {
			flipX = false;
		} else if (intentState.has(MOVE_LEFT)) {
			flipX = true;
		}

		if (grounded) {
			if (intentState.has(MOVE_RIGHT)) {
				nextAnim = anims.Run;
			} else if (intentState.has(MOVE_LEFT)) {
				nextAnim = anims.Run;
			} else {
				nextAnim = anims.Idle;
			}
		} else {
			nextAnim = anims.Jump;
		}

		playAnimIfNotAlready(nextAnim);
	}

	override function kill() {
		super.kill();

		PlayState.ME.removeEnemy(this);
		body.remove();

		if (source != null) {
			source.queueReset();
		}
	}
}
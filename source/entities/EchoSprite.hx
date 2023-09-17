package entities;

import echo.Body;
import flixel.FlxSprite;
import echo.data.Data.CollisionData;

using echo.FlxEcho;

class EchoSprite extends FlxSprite {
	public var body:Body;

	@:access(echo.FlxEcho)
	public function new(X:Float, Y:Float) {
		super(X, Y);

		configSprite();
		body = makeBody();

		// XXX: We want to force position and rotation immediately
		if (body != null) {
			body.update_body_object();
		}
	}

	public function configSprite() {}

	public function makeBody():Body {
		return null;
	}

	public function handleEnter(other:Body, data:Array<CollisionData>) {

	}

	public function handleStay(other:Body, data:Array<CollisionData>) {

	}

	public function handleExit(other:Body) {
		
	}
}
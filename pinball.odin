package main

import "base:runtime"
import "core:fmt"
import im "shared:odin-imgui"
import gl "vendor:OpenGL"
import b2 "vendor:box2d"
import rl "vendor:raylib"


PinBall :: struct {
	left_joint, right_joint  : b2.JointId,
	ball_id : b2.BodyId,
	using sample : Sample,
}

pinball_reset_camera :: proc(pinball: ^PinBall){
	{
		cam.zoom = 45.0
		cam.offset = {940, 141}
	}
}

pinball_create :: proc(settings: ^Settings) -> ^PinBall{

	pinball := new(PinBall)
	using pinball

	sample_init(&sample, settings);

	settings.draw_joints = false


	//Ground body
	ground_id : b2.BodyId

	{

		body_def := b2.DefaultBodyDef()

		ground_id = b2.CreateBody(world_id, body_def)

		vs : [5]b2.Vec2 = { { -8.0, 6.0 }, { -8.0, 20.0 }, { 8.0, 20.0 }, { 8.0, 6.0 }, { 0.0, -2.0 } }

		chain_def := b2.DefaultChainDef()
		chain_def.points = &vs[0]
		chain_def.count = 5
		chain_def.isLoop = true

		c := b2.CreateChain(ground_id, chain_def)
	}

	//Flippers
	{
		p1 : b2.Vec2 = { -2.0, 0.0}
		p2 : b2.Vec2 = { 2.0,  0.0}

		body_def := b2.DefaultBodyDef()
		body_def.type = .dynamicBody
		body_def.enableSleep = false

		body_def.position = p1
		left_flipper_id := b2.CreateBody(world_id,  body_def)

		body_def.position = p2
		right_flipper_id := b2.CreateBody(world_id, body_def)

		box := b2.MakeBox(1.75, 0.2)
		shape_def := b2.DefaultShapeDef()

		p := b2.CreatePolygonShape(left_flipper_id, shape_def, box)
		p =  b2.CreatePolygonShape(right_flipper_id, shape_def, box)

		jointDef := b2.DefaultRevoluteJointDef();
		jointDef.bodyIdA       = ground_id;
		jointDef.localAnchorB  = b2.Vec2_zero;
		jointDef.enableMotor    = true;
		jointDef.maxMotorTorque = 1000.0;
		jointDef.enableLimit    = true;

		jointDef.motorSpeed = 0.0;
		jointDef.localAnchorA = p1;
		jointDef.bodyIdB = left_flipper_id;
		jointDef.lowerAngle = -30.0 * b2.PI / 180.0;
		jointDef.upperAngle = 5.0 * b2.PI/ 180.0;
		left_joint = b2.CreateRevoluteJoint( world_id , jointDef );

		jointDef.motorSpeed = 0.0
		jointDef.localAnchorA = p2
		jointDef.bodyIdB = right_flipper_id
		jointDef.lowerAngle = -5.0 * b2.PI/ 180.0
		jointDef.upperAngle = 30.0 * b2.PI/ 180.0
		right_joint = b2.CreateRevoluteJoint( world_id, jointDef );
	}

	//Spinners


	{
		bodyDef := b2.DefaultBodyDef();
		bodyDef.type = .dynamicBody ;
		bodyDef.position = { -4.0, 17.0 };

		bodyId := b2.CreateBody( world_id , bodyDef );

		shapeDef := b2.DefaultShapeDef();
		box1 := b2.MakeBox( 1.5, 0.125 );
		box2 := b2.MakeBox( 0.125, 1.5 );

		s1 := b2.CreatePolygonShape( bodyId, shapeDef, box1 );
		s2 := b2.CreatePolygonShape( bodyId, shapeDef, box2 );

		jointDef := b2.DefaultRevoluteJointDef();
		jointDef.bodyIdA = ground_id;
		jointDef.bodyIdB = bodyId;
		jointDef.localAnchorA = bodyDef.position;
		jointDef.localAnchorB = b2.Vec2_zero;
		jointDef.enableMotor = true;
		jointDef.maxMotorTorque = 0.1;
		j := b2.CreateRevoluteJoint( world_id , jointDef )

		bodyDef.position = { 4.0, 8.0 };
		bodyId = b2.CreateBody( world_id , bodyDef );
		s1 = b2.CreatePolygonShape( bodyId, shapeDef, box1 );
		s2 = b2.CreatePolygonShape( bodyId, shapeDef, box2 );
		jointDef.localAnchorA = bodyDef.position;
		jointDef.bodyIdB = bodyId;
		j = b2.CreateRevoluteJoint( world_id , jointDef );
	}

	{
		body_def := b2.DefaultBodyDef()
		body_def.position = { -4.0, 8.0 };

		bodyId := b2.CreateBody( world_id, body_def);

		shapeDef := b2.DefaultShapeDef();
		shapeDef.material.restitution = 1.5;

		circle : b2.Circle= { { 0.0, 0.0 }, 1.0 };
		c := b2.CreateCircleShape( bodyId, shapeDef, circle );

		body_def.position = { 4.0, 17.0 };
		bodyId = b2.CreateBody( world_id , body_def);
		c = b2.CreateCircleShape( bodyId, shapeDef, circle );
	}

	{
		bodyDef :b2.BodyDef = b2.DefaultBodyDef();
		bodyDef.position = { 1.0, 15.0 };
		bodyDef.type = .dynamicBody;
		bodyDef.isBullet = true;

		ball_id = b2.CreateBody( world_id , bodyDef );

		shapeDef := b2.DefaultShapeDef();
		circle :b2.Circle= { { 0.0, 0.0 }, 0.2 };
		c := b2.CreateCircleShape( ball_id, shapeDef, circle );
	}

	return pinball
}


pinball_step :: proc (using pinball : ^PinBall, settings : ^Settings){

	sample_step_basic(&pinball.sample, settings)

	if rl.IsKeyDown(.SPACE){
		b2.RevoluteJoint_SetMotorSpeed(left_joint,    20)
		b2.RevoluteJoint_SetMotorSpeed(right_joint , -20)
	}else{
		b2.RevoluteJoint_SetMotorSpeed(left_joint, -10)
		b2.RevoluteJoint_SetMotorSpeed(right_joint , 10)
	}

}

















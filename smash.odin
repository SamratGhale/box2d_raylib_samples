package main

import b2 "vendor:box2d"


Smash :: struct {
	using sample : Sample
}

smash_reset_camera :: proc(smash : ^Smash){
	{
		cam.offset = {432,432}
		cam.zoom   = 20
	}
}

create_smash :: proc(settings: ^Settings) -> ^Smash{

	smash := new(Smash)
	using smash

	sample_init(&sample, settings)

	b2.World_SetGravity(world_id, b2.Vec2_zero)

	//Big box
	{
		box := b2.MakeBox(4.0, 4.0)

		body_def := b2.DefaultBodyDef()
		body_def.type = .dynamicBody
		body_def.position = {-20, 0}
		body_def.linearVelocity = {40, 0}

		body_id := b2.CreateBody(world_id, body_def)

		shape_def := b2.DefaultShapeDef()
		shape_def.density = 8.0
		s := b2.CreatePolygonShape(body_id, shape_def, box)
	}

	d :f32= 0.4

	box := b2.MakeSquare(0.5 * d)

	body_def := b2.DefaultBodyDef()

	body_def.type = .dynamicBody
	body_def.isAwake = true

	shape_def := b2.DefaultShapeDef()

	columns := 20
	rows    := 10

	for i in 0..<columns{
		for j in 0..<rows{

			body_def.position.x = f32(i) * d + 30.0
			body_def.position.y = (f32(j) -f32(rows)/2.0)  * d 
			body_id := b2.CreateBody(world_id, body_def)
			s := b2.CreatePolygonShape(body_id, shape_def, box)
		}
	}
	return smash
}
smash_step :: proc(using smash: ^Smash, settings: ^Settings){
	sample_step_basic(&sample, settings)
}
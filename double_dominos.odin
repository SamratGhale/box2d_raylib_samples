package main

import b2 "vendor:box2d"

DoubleDomino :: struct {
	using sample: Sample,
}

create_double_domino :: proc(settings: ^Settings)-> ^DoubleDomino{

	dd := new(DoubleDomino)

	using dd
	sample_init(&dd.sample, settings)

	{
		body_def := b2.DefaultBodyDef()
		body_def.position = {0, -1.0}
		ground_id := b2.CreateBody(world_id, body_def)

		box := b2.MakeBox(100, 1)
		shape_def := b2.DefaultShapeDef()
		s := b2.CreatePolygonShape(ground_id, shape_def, box)
	}


	box := b2.MakeBox(0.125, 0.5)

	shape_def := b2.DefaultShapeDef()
	shape_def.material.friction = 0.6

	body_def := b2.DefaultBodyDef()
	body_def.type = .dynamicBody

	count : i32 = 15
	x : f32 = -0.5 * f32(count)


	for  i in 0..<count{
		body_def.position = {x, 0.5}
		body_id := b2.CreateBody(world_id, body_def)
		p := b2.CreatePolygonShape(body_id, shape_def, box)

		if i == 0{
			b2.Body_ApplyLinearImpulse(body_id, b2.Vec2{0.2, 0.0}, b2.Vec2{x, 1.0}, true)
		}
		x += 1.0
	}


	return dd
}

dominos_step :: proc(using domino: ^DoubleDomino, settings: ^Settings){
	sample_step_basic(&sample, settings)
}
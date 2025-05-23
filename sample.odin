package main

import b2 "vendor:box2d"
import rl "vendor:raylib"
import "core:fmt"


ContactPoint :: struct{
    shapeid_a, shapeid_b : b2.ShapeId,
    normal, position     : b2.Vec2,
    persisted            : bool,
    normal_impulse, tangent_impulse, separation: f32,
    constraint_index, color : int,
}

Sample :: struct {
    max_tasks : i32,
    task_count : i32,
    thread_count : i32,

    ground_body_id : b2.BodyId,

    text_line : i32,
    world_id  : b2.WorldId,
    mouse_joint_id : b2.JointId,
    step_count : i32,
    text_increment : i32,
    max_profile : b2.Profile,
    total_profile : b2.Profile
}

sample_init :: proc(using sample: ^Sample, settings: ^Settings){



    world_def := b2.DefaultWorldDef()
    world_def.userTaskContext = rawptr(sample)
    world_def.enableSleep = settings.enable_sleep

    world_id = b2.CreateWorld(world_def)
    text_line = 30
    text_increment = 18
    mouse_joint_id = b2.nullJointId

    max_profile = {} 
    total_profile = {}
}


sample_step_basic :: proc(using sample: ^Sample,  settings : ^Settings){
    time_step := settings.hertz > 0.0 ? 1.0 / settings.hertz : 0.0

    if rl.IsKeyPressed(.P) do settings.pause = !settings.pause

    if settings.pause{
        if settings.single_step{
            settings.single_step = false
        }else{
            time_step = 0
        }

        if draw.show_ui{
            //Draw string
            text_line += text_increment
        }
    }
    b2.World_Step(world_id, time_step, settings.sub_step_count)
    rl.BeginMode2D(cam)
    b2.World_Draw(world_id, &draw.debug_draw)
    rl.EndMode2D()
}

sample_step :: proc(sample: SampleUnion, settings: ^Settings){
    switch v in sample{
        case ^DoubleDomino:{
            dominos_step(v, settings)
        }
        case ^PinBall:{
            pinball_step(v, settings)
        }
        case ^Smash:{
            smash_step(v, settings)
        }
    }
}

reset_camera_proc :: proc {
    smash_reset_camera,
    pinball_reset_camera,
    dd_reset_camera,
}

reset_camera :: proc(sample: SampleUnion){
    switch v in sample{
        case ^DoubleDomino: reset_camera_proc(v)
        case ^PinBall:      reset_camera_proc(v)
        case ^Smash:        reset_camera_proc(v)
    }
}

reset_all :: proc(){
    samples[.DOUBLE_DOMINO] = cast(SampleUnion)create_double_domino(&settings)
    samples[.PINBALL]       = cast(SampleUnion)pinball_create(&settings)
    samples[.SMASH]         = cast(SampleUnion)create_smash(&settings)
}




























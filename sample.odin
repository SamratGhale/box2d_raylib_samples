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


sample_step :: proc(using sample: ^Sample,  settings : ^Settings){
    time_step := settings.hertz > 0.0 ? 1.0 / settings.hertz : 0.0

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
    //draw.debug_draw.drawingBounds = camera_get_view_bounds(camera)
    //draw.debug_draw.useDrawingBounds = settings.user_camera_bounds

    b2.World_Step(world_id, time_step, settings.sub_step_count)
    rl.BeginMode2D(cam)
    FlipYAxis()
    
    b2.World_Draw(world_id, &draw.debug_draw)

    rl.EndMode2D()
    FlipYAxis()
}
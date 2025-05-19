package main

import "vendor:glfw"
import b2 "vendor:box2d"
import im "shared:odin-imgui"
import gl "vendor:OpenGL"
import "base:runtime"
import "core:fmt"
Camera :: struct {
    center : b2.Vec2,
    zoom  : f32,
    width : i32,
    height : i32,
}

camera_convert_screen_to_world :: proc "c" (using cam : Camera,  ps: b2.Vec2) -> b2.Vec2{
    w := f32(width)
    h := f32(height)
    u := ps.x / w
    v := (h - ps.y) /h 
    ratio := w /h
    extents : b2.Vec2 = {zoom  * ratio, zoom } 

    lower := center - extents
    upper := center + extents

    pw :b2.Vec2= { ( 1.0 - u) * lower.x + u * upper.x, (1.0 - v) * lower.y + v * upper.y}
    return pw
}

camera_convert_world_to_screen :: proc "c" (using cam : Camera,  pw: b2.Vec2) -> b2.Vec2{
    w := f32(width)
    h := f32(height)
    ratio := w /h
    extents : b2.Vec2 = {zoom  * ratio, zoom } 

    lower := center - extents
    upper := center + extents

    u := (pw.x - lower.x ) / (upper.x - lower.x)
    v := (pw.y - lower.y ) / (upper.y - lower.y)

    ps :b2.Vec2= { u * w, (1.0 - v) * h}
    return ps
}

// Convert from world coordinates to normalized device coordinates.
// http://www.songho.ca/opengl/gl_projectionmatrix.html
// This also includes the view transform
camera_build_projection_matrix :: proc(using c : ^Camera, m: [^]f32, zBias : f32)
{
    ratio := f32( width ) / f32( height )
    extents :b2.Vec2 = { zoom * ratio, zoom }

    lower := center - extents
    upper := center + extents
    w := upper.x - lower.x
    h := upper.y - lower.y

    m[0] = 2.0 / w
    m[1] = 0.0
    m[2] = 0.0
    m[3] = 0.0

    m[4] = 0.0
    m[5] = 2.0 / h
    m[6] = 0.0
    m[7] = 0.0

    m[8] = 0.0
    m[9] = 0.0
    m[10] = -1.0
    m[11] = 0.0

    m[12] = -2.0 * center.x / w
    m[13] = -2.0 * center.y / h
    m[14] = zBias
    m[15] = 1.0
}



camera_get_view_bounds :: proc(using camera: Camera) -> b2.AABB{
    bounds : b2.AABB
    bounds.lowerBound = camera_convert_screen_to_world(camera, { 0, f32(height)})
    bounds.upperBound = camera_convert_screen_to_world(camera, { f32(width), 0})
    return bounds
}




















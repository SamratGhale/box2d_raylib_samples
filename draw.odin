package main

import "vendor:glfw"
import b2 "vendor:box2d"
import "base:runtime"
import im "shared:odin-imgui"
import "core:math"
import gl "vendor:OpenGL"
import "core:fmt"
import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"
import "core:math/linalg"

Draw :: struct {
    show_ui : bool,

    debug_draw : b2.DebugDraw,
}

draw : Draw

make_rgba8 :: proc "c" (cd: b2.HexColor, alpha : f32) -> rl.Color{
    c := u32(cd)
    return { u8( ( c >> 16 ) & 0xFF ), u8( ( c >> 8 ) & 0xFF ), u8( c & 0xFF ), u8( 0xFF * alpha ) }
}

DrawPolygon :: proc "c" (vertices: [^]b2.Vec2, vertexCount: i32, color: b2.HexColor, ctx: rawptr){

    c := make_rgba8(color, 1.0)

    for i in 0..< vertexCount -1 {
        v1 := vertices[i] 
        v2 := vertices[i + 1] 
        rl.DrawLineV( v1, v2, c)
    }


    v1 := vertices[vertexCount - 1] 
    v2 := vertices[0] 
    rl.DrawLineV(v1, v2, c)


}

DrawSolidPolygon :: proc "c" (transform: b2.Transform, vertices: [^]b2.Vec2, vertexCount: i32, radius: f32, colr: b2.HexColor, ctx: rawptr ){

    context = runtime.default_context()

    new_vertices := make([]b2.Vec2, vertexCount)



    for i in 0..<vertexCount{
        new_vertices[i] = b2.TransformPoint(transform, vertices[i])
    }


    c := make_rgba8(colr, 1.0)
    d := make_rgba8(colr, .5)

    rl.DrawTriangleFan(&new_vertices[0], vertexCount, d)

            // Draw polygon outline
        c.a = 255; // Full alpha for outline
        for i in 0..<vertexCount{
            nextIndex :i32= (i + 1) % vertexCount;
            start :rl.Vector2= { new_vertices[i].x, new_vertices[i].y };
            end :rl.Vector2= { new_vertices[nextIndex].x, new_vertices[nextIndex].y };
            rl.DrawLineV(start, end, c);
        }

    delete(new_vertices)


}

// Draw a circle.
DrawCircle:: proc "c" (center: b2.Vec2, radius: f32, color: b2.HexColor, ctx: rawptr){
    p := center 
    rl.DrawCircleLinesV(p, radius, make_rgba8(color, 1.0))
}

// Draw a solid circle.
DrawSolidCircle:: proc "c" (transform: b2.Transform, radius: f32, color: b2.HexColor, ctx: rawptr){


    context = runtime.default_context()



    c := make_rgba8(color, 1.0)
    d := make_rgba8(color, 0.5)
    p := transform.p 

    rl.BeginBlendMode(.ALPHA)


    //rl.DrawCircleV(p, radius, d)


    segments := 32



    points := make([]rl.Vector2, segments + 2)

    points[0] = p

    for i in 0..=segments{
        angle := f32(i)/f32(segments) * 2.0 * b2.PI

        points[i + 1] = {
            p.x + math.cos(angle) * radius,
            p.y + math.sin(angle) * radius,
        }
    }

    rl.DrawTriangleFan(&points[0], i32(segments + 2), d)





    rl.DrawCircleLinesV(p, radius, c)

        // Draw orientation line (shows rotation from transform)
    orientationEnd :rl.Vector2= {
        p.x + math.cos(b2.Rot_GetAngle(transform.q)) * radius,
        p.y + math.sin(b2.Rot_GetAngle(transform.q)) * radius,
    }
    rl.DrawLineV(p, orientationEnd, c);

    rl.EndBlendMode()
}

// Draw a solid capsule.
DrawSolidCapsule :: proc "c" (p1, p2: b2.Vec2, radius: f32, color: b2.HexColor, ctx: rawptr){
    c := make_rgba8(color, 0.5)

    start : rl.Vector2 = p1
    end   : rl.Vector2 = p2


    dir :rl.Vector2 = {end.x - start.x, end.y - start.y }

    length := math.sqrt(dir.x * dir.x + dir.y * dir.y)

    if length > 0{
        //Normalize direction
        dir.x /= length
        dir.y /= length

        //Perpendicular vector

        perp : rl.Vector2 = { -dir.y, dir.x}

                // Calculate rectangle vertices
        rectVertices: [4]rl.Vector2 = {
            { start.x + perp.x * radius, start.y + perp.y * radius },
            { end.x + perp.x * radius, end.y + perp.y * radius },
            { end.x - perp.x * radius, end.y - perp.y * radius },
            { start.x - perp.x * radius, start.y - perp.y * radius }
        };

                // Draw filled rectangle (center part of capsule)
        rl.DrawTriangleFan(&rectVertices[0], 4, c);
        
        // Draw filled circles at ends
        rl.DrawCircleV(start, radius, c);
        rl.DrawCircleV(end, radius,   c);
    }else{
        //If points are same draw a circle
        rl.DrawCircleV(start, radius, c)
    }

        // Draw outline with full alpha
    
    // Draw capsule outline
    if (length > 0)
    {
        // Draw connecting lines
        perp : rl.Vector2 = { -dir.y, dir.x };
        
        topRight :rl.Vector2= { start.x + perp.x * radius, start.y + perp.y * radius };
        bottomRight :rl.Vector2= { end.x + perp.x * radius, end.y + perp.y * radius };
        rl.DrawLineV(topRight, bottomRight, c);
        
        topLeft :rl.Vector2= { start.x - perp.x * radius, start.y - perp.y * radius };
        bottomLeft :rl.Vector2= { end.x - perp.x * radius, end.y - perp.y * radius };
        rl.DrawLineV(topLeft, bottomLeft, c);
        
        // Draw semicircle arcs
        segments :f32= 16;
        angleStep :f32 = b2.PI / segments;
        angle := math.atan2(dir.y, dir.x);
        
        // Draw first semicircle (start point)
        for i in 0..=segments{
            a := angle + b2.PI /2 + angleStep * i;
            p1 :rl.Vector2 = { start.x + math.cos(a) * radius, start.y + math.sin(a) * radius };
            p2 :rl.Vector2 = { start.x + math.cos(a + angleStep) * radius, start.y + math.sin(a + angleStep) * radius };
            rl.DrawLineV(p1, p2, c);
        }
        
        // Draw second semicircle (end point)
        for i in 0..=segments{
            a := angle - b2.PI /2 + angleStep * i;
            p1 :rl.Vector2= { end.x + math.cos(a) * radius, end.y + math.sin(a) * radius };
            p2 :rl.Vector2= { end.x + math.cos(a + angleStep) * radius, end.y + math.sin(a + angleStep) * radius };
            rl.DrawLineV(p1, p2, c);
        }
    }
    else
    {
        // If points are the same, just draw circle outline
        rl.DrawCircleLines(i32(start.x), i32(start.y), radius, c);
    }

}

// Draw a line segment.
DrawSegment:: proc "c" (p1, p2: b2.Vec2, color: b2.HexColor, ctx: rawptr){
    c := make_rgba8(color, 1)
    rl.DrawLineV(p1, p2, c)
}

// Draw a transform. Choose your own length scale.
DrawTransform :: proc "c" (transform: b2.Transform, ctx: rawptr){

    k_axis_scale :f32= 0.4

    p1 := transform.p
    p2 : b2.Vec2


    //Draw x-axis (red)
    p2 = p1 + k_axis_scale * b2.Rot_GetXAxis(transform.q)
    DrawSegment(p1, p2, b2.HexColor.Red, nil)

    //Draw y-axis (red)
    p2 = p1 + k_axis_scale * b2.Rot_GetYAxis(transform.q)
    DrawSegment(p1, p2, b2.HexColor.Green, nil)

}

DrawPoint :: proc "c" (p: b2.Vec2, size: f32, color: b2.HexColor, ctx: rawptr){

    c := make_rgba8(color, 1)
    rl.DrawCircleV(p, size, c)
}

// Draw a string in world space.
DrawString :: proc "c" (p: b2.Vec2, s: cstring, color: b2.HexColor, ctx: rawptr){
    //rl.DrawText(s, i32(p.x), i32(p.y), 20, rl.BLACK)


    rl.EndMode2D()
    FlipYAxis()

    c := make_rgba8(color, 1.0)

    p := p
    p *= cam.zoom
    p.y = f32(rl.GetRenderHeight())/1.1 - p.y
    p.x += cam.offset.x
    rl.DrawText(s, i32(p.x), i32(p.y), 15, c)

    rl.BeginMode2D(cam)
    FlipYAxis()

    
}



draw_create :: proc(using draw : ^Draw){

    debug_draw.DrawPolygonFcn       = DrawPolygon
    debug_draw.DrawSolidPolygonFcn  = DrawSolidPolygon
    debug_draw.DrawCircleFcn        = DrawCircle
    debug_draw.DrawSolidCircleFcn = DrawSolidCircle
    debug_draw.DrawSolidCapsuleFcn  = DrawSolidCapsule
    debug_draw.DrawSegmentFcn       = DrawSegment
    debug_draw.DrawTransformFcn     = DrawTransform
    debug_draw.DrawPointFcn         = DrawPoint
    debug_draw.DrawStringFcn        = DrawString


    debug_draw.drawBounds = false
    debug_draw.drawShapes = true
    debug_draw.drawJoints = true
    debug_draw.drawJointExtras = false
    debug_draw.drawMass = false
    debug_draw.drawContacts = true
    debug_draw.drawFrictionImpulses = true
    debug_draw.drawContactNormals = true
    debug_draw.drawBodyNames = false

}
















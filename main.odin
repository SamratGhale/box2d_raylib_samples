package main

import "base:runtime"
import "core:fmt"
import im "shared:odin-imgui"
import gl "vendor:OpenGL"
import b2 "vendor:box2d"
import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

/*
	Attempt to simulate the samples of box2d from c++ code to odin  using imgui, box2d and glfw
*/

imgui_rt : rl.RenderTexture2D

Settings :: struct {
	sample_index : i32,
	window_width:  i32,
	window_height: i32,
	workerCount:   i32,
	window_scale:  f32,

	hertz : f32,
	sub_step_count, worker_count : i32,

	user_camera_bounds : bool,
	draw_shapes        : bool,
	draw_joints        : bool,
	draw_joints_extras : bool,
	draw_bounds        : bool,
	draw_mass          : bool,
	draw_body_names    : bool,
	draw_contact_points: bool,
	draw_contact_normals   : bool,
	draw_contact_impulses  : bool,
	draw_contact_features  : bool,
	draw_friction_impulses : bool,
	draw_islands  	       : bool,
	draw_graph_colors      : bool,
	draw_counters          : bool,
	draw_profile           : bool,
	enable_warm_starting   : bool,
	enable_continious      : bool,
	enable_sleep           : bool,
	pause                  : bool,
	single_step            : bool,
	restart                : bool,
}

DefaultSettings :: proc () -> Settings{
	return Settings{
		sample_index  = 0,
		window_width  = 1920,
		window_height = 1080,
		window_scale  = 1,

		hertz = 60.0,
		sub_step_count = 4,
		worker_count   = 1,
		user_camera_bounds = false,
		draw_shapes        = false,
		draw_joints        = false,
		draw_joints_extras = false,
		draw_bounds        = false,
		draw_mass          = false,
		draw_body_names    = false,
		draw_contact_points= false,
		draw_contact_normals   = false,
		draw_contact_impulses  = false,
		draw_contact_features  = false,
		draw_friction_impulses = false,
		draw_islands  	       = false,
		draw_graph_colors      = false,
		draw_counters          = false,
		draw_profile           = true,
		enable_warm_starting   = false,
		enable_continious      = true,
		enable_sleep           = false,
		pause                  = false,
		single_step            = false,
		restart                = false,

	}
}

settings := DefaultSettings()
camera: Camera

FlipYAxis :: proc "c" ()
{
    // Direct OpenGL call to flip Y-axis
    rlgl.MatrixMode(rlgl.PROJECTION);
    rlgl.Scalef(1.0, -1.0, 0.0);  // Flip Y-axis
    rlgl.MatrixMode(rlgl.MODELVIEW);
}

cam : rl.Camera2D

main :: proc() {

	settings.workerCount = 4

	settings.window_height = 1080
	settings.window_width = 1920


	camera.height = settings.window_height
	camera.width = settings.window_width

	rl.SetConfigFlags({.MSAA_4X_HINT, .INTERLACED_HINT, .VSYNC_HINT, })
	rl.InitWindow(settings.window_width, settings.window_height, "Box2d demo")
	rl.SetTargetFPS(60)
	rl.SetExitKey(.KEY_NULL)

	im.CreateContext(nil)
	imgui_init()
	io := im.GetIO()
	im.FontAtlas_AddFontFromFileTTF(io.Fonts, "c:\\Windows\\Fonts\\CascadiaMono.ttf", 20)
	build_font_atlas()

	imgui_rt = rl.LoadRenderTexture(settings.window_width, settings.window_height)

	draw_create(&draw)
	pinball := pinball_create(&settings)



	cam.offset = (rl.Vector2){ f32(rl.GetRenderWidth())/2.0, -f32(rl.GetRenderHeight())/1.1};
	cam.rotation = 0;
	cam.zoom = 45.0;





	for !rl.WindowShouldClose(){

		time := rl.GetTime()


		rl.BeginDrawing()


		free_all(context.temp_allocator)	

		{
			imgui_rl_begin()
			rl.BeginTextureMode(imgui_rt)
			rl.ClearBackground(rl.ColorAlpha(rl.WHITE, 0))
			rl.EndTextureMode()
			im.ShowDemoWindow(nil)
		}



		rl.ClearBackground(rl.GRAY)

		pinball_step(pinball, &settings)




		{
			rl.BeginTextureMode(imgui_rt)
			imgui_rl_end()
			rl.EndTextureMode()
		}




	    rl.DrawTexturePro(
		imgui_rt.texture,
		{0, 0, f32(imgui_rt.texture.width), -f32(imgui_rt.texture.height)},
		{0, 0, f32(rl.GetRenderWidth()), -f32(rl.GetRenderHeight())},
		{},
		0,
		rl.WHITE,
	    )
	    rl.DrawFPS(10, 10)


		rl.EndDrawing()


	}
	rl.CloseWindow()
	imgui_shutdown()

}















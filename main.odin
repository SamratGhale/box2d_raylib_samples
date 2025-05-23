package main

import "base:runtime"
import "core:fmt"
import im "shared:odin-imgui"
import "core:reflect"
import gl "vendor:OpenGL"
import b2 "vendor:box2d"
import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

/*
	Attempt to simulate the samples of box2d from c++ code to odin  using imgui, box2d and glfw
*/

imgui_rt : rl.RenderTexture2D
background_rt : rl.RenderTexture2D


SampleUnion :: union {
	^PinBall,
	^DoubleDomino
}

SampleType :: enum{
	PINBALL,
	DOUBLE_DOMINO
}

//sample : SampleUnion


samples : [SampleType]SampleUnion

curr_sample : SampleType

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
//camera: Camera


cam : rl.Camera2D

update_ui :: proc(){

	 if draw.show_ui{
	 	im.Begin("Tools", &draw.show_ui)

	 	if im.BeginTabBar("ControlTabs", {}){
	 		if im.BeginTabItem("Controls"){
	 			im.PushItemWidth(100)
	 			im.SliderInt("Sub-steps", &settings.sub_step_count, 1, 50)
	 			im.SliderFloat("Hertz", &settings.hertz, 5.0, 120, "%.0f hz")

	 			im.PopItemWidth()

	 			im.Separator()

	 			im.Checkbox("Sleep", &settings.enable_sleep)
	 			im.Checkbox("Warm starting",  &settings.enable_warm_starting)
	 			im.Checkbox("Continuous", &settings.enable_continious)
	 			im.Separator()

				im.Checkbox( "Shapes", &draw.debug_draw.drawShapes );
				im.Checkbox( "Joints", &draw.debug_draw.drawJoints );
				im.Checkbox( "Joint Extras", &draw.debug_draw.drawJointExtras );
				im.Checkbox( "Contact Points", &draw.debug_draw.drawContacts);
				im.Checkbox( "Contact Normals", &draw.debug_draw.drawContactNormals );
				im.Checkbox( "Contact Impulses", &draw.debug_draw.drawContactImpulses );
				im.Checkbox( "Friction Impulses", &draw.debug_draw.drawFrictionImpulses );
				im.Checkbox( "Center of Masses", &draw.debug_draw.drawMass );
				im.Checkbox( "Graph Colors", &draw.debug_draw.drawGraphColors );
				im.Checkbox( "Profile", &settings.draw_profile);

				im.SliderFloat( "zoom ", &cam.zoom, 0, 200);
				im.SliderFloat( " offsetx  x", &cam.offset.x , 0, 1920);
				im.SliderFloat( " offsetx  y", &cam.offset.y , 0, 1920);
				im.SliderFloat( " target x", &cam.target.y , 0, 20);
				im.SliderFloat( " target y", &cam.target.x , 0, 20);

				if im.BeginCombo("Program", fmt.ctprint(curr_sample)){
					for type in SampleType{
						if im.Selectable(fmt.ctprint(type)){
							curr_sample = type
						}
					}
					im.EndCombo()
				}


				if im.Button( "reset "){
					reset_all()
				}

				im.EndTabItem()

	 		}
	 		im.EndTabBar()
	 	}
	 	im.End()
	 }

}





main :: proc() {

	settings.workerCount = 4

	settings.window_height = 1080
	settings.window_width = 1920

	//camera.height = settings.window_height
	//camera.width = settings.window_width

	rl.SetConfigFlags({.MSAA_4X_HINT, .INTERLACED_HINT, .VSYNC_HINT, })
	rl.InitWindow(settings.window_width, settings.window_height, "Box2d demo")
	rl.SetTargetFPS(60)
	rl.SetExitKey(.KEY_NULL)
	b2.SetLengthUnitsPerMeter(128)

	im.CreateContext(nil)
	imgui_init()
	io := im.GetIO()
	im.FontAtlas_AddFontFromFileTTF(io.Fonts, "c:\\Windows\\Fonts\\CascadiaMono.ttf", 20)
	build_font_atlas()

	imgui_rt = rl.LoadRenderTexture(settings.window_width, settings.window_height)

	//To flip
	background_rt = rl.LoadRenderTexture(settings.window_width, settings.window_height)
	cam.target = {0, 0}
	cam.offset = (rl.Vector2){ 0,f32(rl.GetRenderHeight()/6)};


	draw_create(&draw)

	curr_sample = .PINBALL

	reset_all()

	draw.show_ui = true

	//rlgl.DisableBackfaceCulling()

	for !rl.WindowShouldClose(){

		free_all(context.temp_allocator)	

		{
			imgui_rl_begin()
			rl.BeginTextureMode(imgui_rt)
			rl.ClearBackground(rl.ColorAlpha(rl.WHITE, 0))

			rl.EndTextureMode()
			rl.BeginTextureMode(background_rt)
			rl.ClearBackground(rl.ColorAlpha(rl.GRAY, 0))
			rl.EndTextureMode()
		}

		rl.BeginTextureMode(background_rt)
		sample_step(samples[curr_sample], &settings)
		rl.EndTextureMode()


		update_ui()
		{
			rl.BeginTextureMode(imgui_rt)
			imgui_rl_end()
			rl.EndTextureMode()
		}



		rl.BeginDrawing()

		rl.ClearBackground(rl.GRAY)
		rl.DrawTexturePro(
			background_rt.texture,
			{0, 0, f32(background_rt.texture.width), f32(background_rt.texture.height)},
			{0, 0, f32(rl.GetRenderWidth()), f32(rl.GetRenderHeight())},
			{},
			0,
			rl.ColorAlpha(rl.WHITE, 1),
			)

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















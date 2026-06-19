package main

import "core:fmt"
import "core:c"
import sdl "vendor:sdl2"

WIDTH :: 800
HEIGHT :: 600
FPS :: 60
DELTA_TIME :f32: 1 / FPS

RED   ::      0xFF0000FF
BLACK ::      0x000000FF
WHITE ::      0xFFFFFFFF
BACKGROUND :: 0x181818FF

set_unhexed_color :: proc(renderer: ^sdl.Renderer, hex_color: u32) {
    sdl.SetRenderDrawColor(renderer, 
        u8((hex_color >> (8*3)) & 0xFF),
        u8((hex_color >> (8*2)) & 0xFF),
        u8((hex_color >> (8*1)) & 0xFF),
        u8((hex_color >> (8*0)) & 0xFF)
    )
}

render_and_update :: proc(renderer: ^sdl.Renderer, dt: f32) {
    ball_dx, ball_dy := 1, 1
    set_unhexed_color(renderer, BACKGROUND)
    sdl.RenderClear(renderer)
    // renderering here
    
    x := 0
    y := 0

    ball_speed := 100
    ball_rect : sdl.Rect = sdl.Rect {
        x = i32(x),
        y = i32(y),
        w = 50,
        h = 50
    }

    x += ball_dx*ball_speed
    y += ball_dy*ball_speed

    set_unhexed_color(renderer, RED)
    sdl.RenderFillRect(renderer, &ball_rect)
    sdl.RenderPresent(renderer)
}

main :: proc() {
    if sdl.Init(sdl.INIT_VIDEO) != 0 {
        fmt.println("SDL Could not initialize properly");
        return
    }
    defer sdl.Quit()

    window := sdl.CreateWindow("Game", sdl.WINDOWPOS_CENTERED, 
                sdl.WINDOWPOS_CENTERED, WIDTH, HEIGHT, sdl.WINDOW_SHOWN)

    if window == nil {
        return
    }
    defer sdl.DestroyWindow(window)

    renderer := sdl.CreateRenderer(window, -1, sdl.RENDERER_ACCELERATED)
    if renderer == nil {
        return
    }
    
    defer sdl.DestroyRenderer(renderer)

    event: sdl.Event
    quit := false
    pause := false

    // frame cap
    for !quit {

        for sdl.PollEvent(&event) {
			#partial switch event.type {
			case .QUIT:
                quit = true
			case .KEYDOWN:
				#partial switch event.key.keysym.scancode {
				case .ESCAPE:
					quit = true
                case .SPACE:
                    pause = true
				}
			}
        }

        if !pause {
            render_and_update(renderer, DELTA_TIME)
        }
        sdl.Delay(1000/FPS)
        
    }
}

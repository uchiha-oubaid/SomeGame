package main

import     "core:fmt"
import     "core:c"
//import math"core:math/linalg/hlsl"
import sdl "vendor:sdl2"
import img "vendor:sdl2/image"

WIDTH :: 800
HEIGHT :: 600
FPS :: 60
DELTA_TIME :f32: 1.0 / FPS
FONT_ATLAS_WIDTH :: 96
FONT_ATLAS_HEIGHT :: 48

FONT_CHAR_WIDTH :: 6
FONT_CHAR_HEIGHT :: 8

FONT_ATLAS_COLS :: 16
FONT_ATLAS_ROWS :: 6

RED   ::      0xFF0000FF
BLACK ::      0x000000FF
GREEN ::      0x00FF00FF
WHITE ::      0xFFFFFFFF
BACKGROUND :: 0x181818FF

ball_dx, ball_dy :f32 = 1, 1
ball_rect : sdl.FRect = sdl.FRect {
    x = 50,
    y = 10,
    w = 50,
    h = 50
}

set_unhexed_color :: proc(renderer: ^sdl.Renderer, hex_color: u32) {
    sdl.SetRenderDrawColor(renderer, 
        u8((hex_color >> (8*3)) & 0xFF),
        u8((hex_color >> (8*2)) & 0xFF),
        u8((hex_color >> (8*1)) & 0xFF),
        u8((hex_color >> (8*0)) & 0xFF)
    )
}

create_texture_from_font :: proc(renderer: ^sdl.Renderer, filepath: cstring, color: u32) -> ^sdl.Texture {
    font_surface := img.Load(filepath)
    if font_surface == nil {
        fmt.println("File does not exist")
        return nil
    }

    sdl.SetSurfaceColorMod(font_surface,
        u8((color >> (8*3)) & 0xFF),
        u8((color >> (8*2)) & 0xFF),
        u8((color >> (8*1)) & 0xFF))
    defer sdl.FreeSurface(font_surface)

    font_texture := sdl.CreateTextureFromSurface(renderer, font_surface)
    return font_texture
}

create_surface_from_font :: proc(renderer: ^sdl.Renderer, filepath: cstring) -> ^sdl.Surface {
    font_surface := img.Load(filepath)
    if font_surface == nil {
        fmt.println("File does not exist")
        return nil
    }
    defer sdl.FreeSurface(font_surface)
    return font_surface
}

// NOTE: color format is RRGGBB
render_text :: proc(renderer: ^sdl.Renderer, x, y: i32, text: string, scale: i32, filepath: cstring="./assets/ascii.png") {
    //font_surface := create_surface_from_font(renderer, filepath)

    for char, index in text {
        char_index := char - 32
        i_index := i32(index)

        char_col := i32(char_index % FONT_ATLAS_COLS)
        char_row := i32(char_index / FONT_ATLAS_COLS)
        src_rect := sdl.Rect {
            x = char_col*FONT_CHAR_WIDTH,
            y = char_row*FONT_CHAR_HEIGHT,
            w = FONT_CHAR_WIDTH,
            h = FONT_CHAR_HEIGHT
        }
        dst_rect := sdl.Rect {
            x = x+i_index*FONT_CHAR_WIDTH*scale,
            y = y,
            w = FONT_CHAR_WIDTH*scale,
            h = FONT_CHAR_HEIGHT*scale
        }

        font_texture := create_texture_from_font(renderer, filepath, GREEN)
        sdl.RenderCopy(renderer, font_texture, &src_rect, &dst_rect);
        defer sdl.DestroyTexture(font_texture)
    }
}

pause := false
render_and_update :: proc(renderer: ^sdl.Renderer, dt: f32) {
    set_unhexed_color(renderer, BACKGROUND)
    sdl.RenderClear(renderer)

    // TODO replace the rect with an actual texture
    ball_speed :f32 = 500
    set_unhexed_color(renderer, RED)
    sdl.RenderFillRectF(renderer, &ball_rect)
    // -------------------------------------------

    if !pause {
        if ball_rect.x < 0 || ball_rect.x + ball_rect.w > WIDTH  {ball_dx *= -1}
        if ball_rect.y < 0 || ball_rect.y + ball_rect.h > HEIGHT {ball_dy *= -1}
        ball_rect.x += ball_dx*ball_speed*dt
        ball_rect.y += ball_dy*ball_speed*dt
    }
    else {
        scale := 4
        text : string = "Game paused !" 
        text_length := FONT_CHAR_WIDTH*len(text)*scale
        render_text(renderer, 
            i32(WIDTH/2 - text_length/2), i32(HEIGHT/2 - FONT_CHAR_HEIGHT/2), 
            text, i32(scale))
    }
    sdl.RenderPresent(renderer)
}

main :: proc() {
    if sdl.Init(sdl.INIT_VIDEO) != 0 {
        fmt.println("SDL Could not initialize properly");
        return
    }
    defer sdl.Quit()

    img.Init(img.INIT_PNG)
    defer img.Quit()

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
                    pause = !pause
				}
			}
        }

        render_and_update(renderer, DELTA_TIME)
        sdl.Delay(1000 / FPS)
    }
}

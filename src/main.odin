package main

import     "core:fmt"
import     "core:c"
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

RED   ::      0xFF0000FF
BLACK ::      0x000000FF
WHITE ::      0xFFFFFFFF
BACKGROUND :: 0x181818FF

ball_dx, ball_dy :f32 = 1, 1
ball_rect : sdl.FRect = sdl.FRect {
    x = 0,
    y = 0,
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

create_texture_from_font :: proc(renderer: ^sdl.Renderer, filepath: cstring) -> ^sdl.Texture {
    font_surface := img.Load(filepath)
    if font_surface == nil {
        fmt.println("File does not exist")
        return nil
    }
    defer sdl.FreeSurface(font_surface)
    font_texture := sdl.CreateTextureFromSurface(renderer, font_surface)
    return font_texture
}

render_char :: proc(renderer :^sdl.Renderer, filepath: cstring, x, y: i32, char: c.char, scale: i32) {
    char_index := i32(char) - 32
    char_col := char_index % FONT_ATLAS_WIDTH
    char_row := char_index / FONT_ATLAS_WIDTH

    src_rect := sdl.Rect {
        x = char_col*FONT_ATLAS_WIDTH,
        y = char_row*FONT_ATLAS_HEIGHT,
        w = FONT_CHAR_WIDTH,
        h = FONT_CHAR_HEIGHT
    }
    dst_rect := sdl.Rect {
        x = x,
        y = y,
        w = FONT_CHAR_WIDTH*scale,
        h = FONT_CHAR_HEIGHT*scale
    }
    char_font := create_texture_from_font(renderer, filepath)
    sdl.RenderCopy(renderer, char_font, &src_rect, &dst_rect);
    defer sdl.DestroyTexture(char_font)
}

render_string :: proc(renderer: ^sdl.Renderer, text: cstring, scale: i32) {
    filepath : cstring = "./assets/ascii.png"
    src_rect := sdl.Rect {
        x = 0,
        y = 0,
        w = FONT_ATLAS_WIDTH,
        h = FONT_ATLAS_HEIGHT
    }
    dst_rect := sdl.Rect {
        x = 0,
        y = 0,
        w = FONT_ATLAS_WIDTH*scale,
        h = FONT_ATLAS_HEIGHT*scale
    }
    font := create_texture_from_font(renderer, filepath)
    sdl.RenderCopy(renderer, font, &src_rect, &dst_rect);
    defer sdl.DestroyTexture(font)
}

render_and_update :: proc(renderer: ^sdl.Renderer, dt: f32) {
    set_unhexed_color(renderer, BACKGROUND)
    sdl.RenderClear(renderer)
    // renderering here

    //render_string(renderer, "test", 4)
    render_char(renderer, "/home/lOobaid/code/odin-game/assets/ascii.png", 10, 10, 'c', 5)

    ball_speed :f32 = 500
    set_unhexed_color(renderer, RED)
    if ball_rect.x < 0 || ball_rect.x + ball_rect.w > WIDTH  {ball_dx *= -1}
    if ball_rect.y < 0 || ball_rect.y + ball_rect.h > HEIGHT {ball_dy *= -1}

    ball_rect.x += ball_dx*ball_speed*dt
    ball_rect.y += ball_dy*ball_speed*dt

    sdl.RenderFillRectF(renderer, &ball_rect)
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
                    pause = !pause
				}
			}
        }

        if !pause {
            render_and_update(renderer, DELTA_TIME)
        }else {
            // TODO add text indicating pausing
        }
        sdl.Delay(1000 / FPS)
    }
}

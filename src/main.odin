package main

import     "core:fmt"
import     "core:c"
import sdl "vendor:sdl2"
import img "vendor:sdl2/image"

WIDTH ::  1000
HEIGHT :: 900
FPS :: 60
DELTA_TIME :f32: 1.0 / FPS
FONT_ATLAS_WIDTH :: 96
FONT_ATLAS_HEIGHT :: 48

FONT_CHAR_WIDTH :: 6
FONT_CHAR_HEIGHT :: 8

FONT_ATLAS_COLS :: 16
FONT_ATLAS_ROWS :: 6

// COLORS
RED   ::      0xFF0000FF
BLACK ::      0x000000FF
GREEN ::      0x00FF00FF
WHITE ::      0xFFFFFFFF
BACKGROUND :: 0x181818FF
PURPLE ::     0x65577BFF
// NOTE: This is still for testing

ball_dx, ball_dy :f32 = 1, 1
ball_speed :f32 = 500
ball_rect := sdl.FRect {
    x = 80,
    y = 100,
    w = 50,
    h = 50
}

player_dx, player_dy: f32 = 0, 0
player_speed : f32 = 700
player_rect := sdl.FRect {
    x = 70,
    y = 50,
    w = 40,
    h = 40
}


GameState :: enum {
    MENU,
    PLAYING,
    LOST
}

set_unhexed_color :: proc(renderer: ^sdl.Renderer, hex_color: u32) {
    sdl.SetRenderDrawColor(renderer, 
        u8((hex_color >> (8*3)) & 0xFF),
        u8((hex_color >> (8*2)) & 0xFF),
        u8((hex_color >> (8*1)) & 0xFF),
        u8((hex_color >> (8*0)) & 0xFF))
}

create_texture_from_file :: proc(renderer: ^sdl.Renderer, filepath: cstring, color: u32) -> ^sdl.Texture {
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

create_surface_from_file :: proc(renderer: ^sdl.Renderer, filepath: cstring) -> ^sdl.Surface {
    font_surface := img.Load(filepath)
    if font_surface == nil {
        fmt.println("File does not exist")
        return nil
    }
    defer sdl.FreeSurface(font_surface)
    return font_surface
}

// NOTE: color format is RRGGBB
render_text :: proc(renderer: ^sdl.Renderer, x, y: i32, text: string, scale: i32, color: u32, filepath: cstring="./assets/ascii.png") {
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

        font_texture := create_texture_from_file(renderer, filepath, color)
        sdl.RenderCopy(renderer, font_texture, &src_rect, &dst_rect);
        sdl.DestroyTexture(font_texture)
    }
}

SPRITE_SIZE :: 17

render_sprite :: proc(renderer: ^sdl.Renderer, col: u32, row: u32, color: u32, spritesheet_filepath: cstring="./assets/spritesheet.png") {
    spritesheet_texture := create_texture_from_file(renderer, spritesheet_filepath, color)
    defer sdl.DestroyTexture(spritesheet_texture)
    src_rect := sdl.Rect {
        x = i32(col*SPRITE_SIZE),
        y = i32(row*SPRITE_SIZE),
        w = SPRITE_SIZE,
        h = SPRITE_SIZE
    }
    sdl.RenderCopyF(renderer, spritesheet_texture, &src_rect, &ball_rect);
}

pause := false
score : u64 = 0
max_score : u64 = 0
score_step := 1000 // ms
game_state: GameState

render_and_update :: proc(renderer: ^sdl.Renderer, dt: f32) {
    #partial switch game_state {
    case .PLAYING:
        set_unhexed_color(renderer, BACKGROUND)
        sdl.RenderClear(renderer)

        // TODO replace the rect with an actual texture
        set_unhexed_color(renderer, RED)
        //sdl.RenderFillRectF(renderer, &ball_rect)
        render_sprite(renderer, 0, 0, WHITE)

        set_unhexed_color(renderer, WHITE)
        sdl.RenderFillRectF(renderer, &player_rect)
        // -------------------------------------------
        scale := 4
        score_step -= 10
        if score_step <= 0 {
            score += 1
            score_step = 1000
        }

        if score >= max_score {
            max_score = score
        }

        text := fmt.tprintf("Score: %v", score)
        text_length := FONT_CHAR_WIDTH*len(text)*scale
        render_text(renderer, 
            i32(WIDTH/2 - text_length/2), 10, 
            text, i32(scale), WHITE)

        if !pause {
            if ball_rect.x < 0 || ball_rect.x + ball_rect.w > WIDTH  {ball_dx *= -1}
            if ball_rect.y < 0 || ball_rect.y + ball_rect.h > HEIGHT {ball_dy *= -1}
            ball_rect.x += ball_dx*ball_speed*dt
            ball_rect.y += ball_dy*ball_speed*dt

            // Wall loose condition
            if player_rect.x < 0 || player_rect.x + player_rect.w > WIDTH  {game_state = .LOST}
            if player_rect.y < 0 || player_rect.y + player_rect.h > HEIGHT {game_state = .LOST}
            // ball loose condition
            if sdl.HasIntersectionF(&ball_rect, &player_rect) {game_state = .LOST}

            player_rect.x += player_dx*player_speed*dt
            player_rect.y += player_dy*player_speed*dt

        }
        else {
            scale := 4
            text : string = "Game paused!" 
            text_length := FONT_CHAR_WIDTH*len(text)*scale
            render_text(renderer, 
                i32(WIDTH/2 - text_length/2), i32(HEIGHT/2 - FONT_CHAR_HEIGHT/2), 
                text, i32(scale), GREEN)
        }
        sdl.RenderPresent(renderer)
    case .LOST:
        set_unhexed_color(renderer, RED)
        sdl.RenderClear(renderer)

        // "You lost" text rendering
        scale := 4
        text : string = "You lost!" 
        text_length := FONT_CHAR_WIDTH*len(text)*scale
        render_text(renderer, 
            i32(WIDTH/2 - text_length/2), i32(HEIGHT/2 - FONT_CHAR_HEIGHT/2), 
            text, i32(scale), WHITE)

        high_score_text := fmt.tprintf("Your score: %v", max_score)
        render_text(renderer, 
            i32(WIDTH/2 - text_length/2 - 50), i32(HEIGHT/2 - FONT_CHAR_HEIGHT/2) + 50, 
            high_score_text, i32(scale), WHITE)

        sdl.RenderPresent(renderer)
    }
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
    lost := false

    game_state = .PLAYING

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
                case .A:
                    player_dx = -1
                    player_dy = 0
                case .W:
                    player_dy = -1
                    player_dx = 0
                case .S:
                    player_dy = 1
                    player_dx = 0
                case .D:
                    player_dx = 1
                    player_dy = 0
                }
			}
        }

        render_and_update(renderer, DELTA_TIME)
        sdl.Delay(1000 / FPS)
    }
}

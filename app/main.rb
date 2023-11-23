class Game
  attr_gtk

  def tick
    defaults
    render
    input
    calc
    post_calc
  end

  def defaults
    return if state.tick_count != 0

    player.x                     = 512
    player.y                     = 800
    player.size                  = 50
    player.dx                    = 0
    player.dy                    = 0
    player.action                = :falling
    player.is_right              = true

    player.max_speed             = 20
    player.jump_power            = 15
    player.jump_air_time         = 15
    player.jump_increase_power   = 1

    state.enemies = []
    enemies << {
      x: 64 * 15,
      y: 64,
      is_right: false,
    }
    enemies << {
      x: 64 * 10,
      y: 64 * 4,
      is_right: false,
    }
    enemies << {
      x: 64 * 2,
      y: 64,
      is_right: true,
    }
    state.number_of_enemies_destoryed = 0

    state.gravity                = -1
    state.drag                   = 0.001
    state.tile_size              = 64
    state.tiles                ||= [
      # { ordinal_x:  0, ordinal_y: 0 },
      # { ordinal_x:  1, ordinal_y: 0 },
      { ordinal_x:  2, ordinal_y: 0 },
      { ordinal_x:  3, ordinal_y: 0 },
      { ordinal_x:  4, ordinal_y: 0 },
      { ordinal_x:  5, ordinal_y: 0 },
      { ordinal_x:  6, ordinal_y: 0 },
      { ordinal_x:  7, ordinal_y: 0 },
      { ordinal_x:  8, ordinal_y: 0 },
      { ordinal_x:  9, ordinal_y: 0 },
      { ordinal_x: 10, ordinal_y: 0 },
      { ordinal_x: 11, ordinal_y: 0 },
      { ordinal_x: 12, ordinal_y: 0 },
      { ordinal_x: 13, ordinal_y: 0 },
      { ordinal_x: 14, ordinal_y: 0 },
      { ordinal_x: 15, ordinal_y: 0 },
      { ordinal_x: 16, ordinal_y: 0 },
      { ordinal_x: 17, ordinal_y: 0 },
      # { ordinal_x: 18, ordinal_y: 0 },
      # { ordinal_x: 19, ordinal_y: 0 },

      { ordinal_x:  7, ordinal_y: 3 },
      { ordinal_x:  8, ordinal_y: 3 },
      { ordinal_x:  9, ordinal_y: 3 },
      { ordinal_x: 10, ordinal_y: 3 },
      { ordinal_x: 11, ordinal_y: 3 },
    ]

    tiles.each do |t|
      t.rect = { x: t.ordinal_x * 64,
                 y: t.ordinal_y * 64,
                 w: 64,
                 h: 64 }
    end
  end

  def render
    outputs.sprites << {
      x: 0,
      y: 0,
      w: args.grid.w,
      h: args.grid.h,
      path: 'sprites/background1.png'
    }
    render_tiles
    render_player
    render_enemies
    render_weapons
    # render_grid
    render_info
  end

  def input
    input_jump
    input_move
  end

  def calc
    calc_player_rect
    calc_enemies
    calc_weapons
    calc_left
    calc_right
    calc_below
    calc_above
    calc_player_dy
    calc_player_dx
    calc_game_over
  end

  def post_calc
    input_shot
  end

  def render_player
    outputs.sprites << {
      x: player.x,
      y: player.y,
      w: player.size,
      h: player.size,
      flip_horizontally: !player.is_right,
      path: 'sprites/player1.png'
    }
  end

  def render_weapons
    # args.outputs.debug << {
    #   x: 40,
    #   y: args.grid.h - 10,
    #   text: "weapons: #{weapons.count}",
    # }.label!

    weapons.each do |w|
      outputs.sprites << {
        x: w.x,
        y: w.y,
        w: 32,
        h: 32,
        flip_horizontally: !w.is_right,
        path: "sprites/weapon1.png",
      }
    end
  end

  def render_enemies
    enemies.each do |e|
      outputs.sprites << {
        x: e.x,
        y: e.y,
        w: 64,
        h: 64,
        flip_horizontally: !e.is_right,
        path: "sprites/enemy1.png",
      }
    end
  end

  def render_tiles
    outputs.sprites << state.tiles.map do |t|
      t.merge path: 'sprites/tile1.png',
              x: t.ordinal_x * 64,
              y: t.ordinal_y * 64,
              w: 64,
              h: 64
    end
  end

  def render_grid
    if state.tick_count == 0
      outputs[:grid].transient!
      outputs[:grid].background_color = [0, 0, 0, 0]
      outputs[:grid].borders << available_brick_locations
      outputs[:grid].labels  << available_brick_locations.map do |b|
        [
          b.merge(text: "#{b.ordinal_x},#{b.ordinal_y}",
                  x: b.x + 2,
                  y: b.y + 2,
                  size_enum: -3,
                  vertical_alignment_enum: 0,
                  blendmode_enum: 0),
          b.merge(text: "#{b.x},#{b.y}",
                  x: b.x + 2,
                  y: b.y + 2 + 20,
                  size_enum: -3,
                  vertical_alignment_enum: 0,
                  blendmode_enum: 0)
        ]
      end
    end

    outputs.sprites << { x: 0, y: 0, w: 1280, h: 720, path: :grid }
  end

  def render_info
    outputs.labels << {
      x: 20,
      y: args.grid.h - 10,
      text: "Enemy: #{state.number_of_enemies_destoryed}",
    }
  end

  def input_shot
    if inputs.keyboard.key_down.x || inputs.controller_one.key_down.a
      player_shot
    end
  end

  def input_jump
    if inputs.keyboard.key_down.space || inputs.keyboard.key_down.z || inputs.controller_one.key_down.b
      player_jump
    end

    if inputs.keyboard.key_held.space || inputs.keyboard.key_held.z || inputs.controller_one.key_held.b
      player_jump_increase_air_time
    end
  end

  def input_move
    if player.dx.abs < 20
      if inputs.left
        player.dx -= 2
        player.is_right = false
      elsif inputs.right
        player.dx += 2
        player.is_right = true
      end
    end
  end

  def calc_game_over
    is_hit_enemy = enemies.find do |e|
      enemy_rect = { x: e.x, y: e.y, w: 64, h: 64 }
      player.rect.intersect_rect? enemy_rect
    end

    if is_hit_enemy || player.y < -64 
      player.x = 64
      player.y = 800
      player.dx = 0
      player.dy = 0
    end
  end

  def calc_player_rect
    player.rect      = player_current_rect
    player.next_rect = player_next_rect
    player.prev_rect = player_prev_rect
  end

  def calc_player_dx
    player.dx  = player_next_dx
    player.x  += player.dx
  end

  def calc_player_dy
    player.y  += player.dy
    player.dy  = player_next_dy
  end

  def calc_below
    return unless player.dy < 0
    tiles_below = tiles_find { |t| t.rect.top <= player.prev_rect.y }
    collision = tiles_find_colliding tiles_below, (player.rect.merge y: player.next_rect.y)
    if collision
      player.y  = collision.rect.y + state.tile_size
      player.dy = 0
      player.action = :standing
    else
      player.action = :falling
    end
  end

  def calc_left
    return unless player.dx < 0 && player_next_dx < 0
    tiles_left = tiles_find { |t| t.rect.right <= player.prev_rect.left }
    collision = tiles_find_colliding tiles_left, (player.rect.merge x: player.next_rect.x)
    return unless collision
    player.x  = collision.rect.right
    player.dx = 0
  end

  def calc_right
    return unless player.dx > 0 && player_next_dx > 0
    tiles_right = tiles_find { |t| t.rect.left >= player.prev_rect.right }
    collision = tiles_find_colliding tiles_right, (player.rect.merge x: player.next_rect.x)
    return unless collision
    player.x  = collision.rect.left - player.rect.w
    player.dx = 0
  end

  def calc_above
    return unless player.dy > 0
    tiles_above = tiles_find { |t| t.rect.y >= player.prev_rect.y }
    collision = tiles_find_colliding tiles_above, (player.rect.merge y: player.next_rect.y)
    return unless collision
    player.dy = 0
    player.y  = collision.rect.bottom - player.rect.h
  end

  def calc_enemies
    while enemies.count < 3
      enemies << {
        x: 64 * rand(20),
        y: 64 * (rand(9) + 1),
        is_right: rand(2) == 1,
      }
    end

    enemies.each do |e|
      e.x += e.is_right ? 2 : -2
      e.x = -64 if e.x > args.grid.w
      e.x = args.grid.w if e.x < -64
    end

    enemies.delete_if do |e|
      enemy_rect = { x: e.x, y: e.y, w: 64, h: 64 }
      weapons.find do |w|
        weapon_rect = { x: w.x, y: w.y, w: 32, h: 32 }
        if enemy_rect.intersect_rect?(weapon_rect)
          w.dead = true
          state.number_of_enemies_destoryed += 1
          true
        else
          false
        end
      end
    end
  end

  def calc_weapons
    weapons.each do |w|
      dir = w.is_right ? 1 : -1
      w.x += 12 * dir
    end

    weapons.delete_if do |w|
      w.dead ||
      w.x > args.grid.w ||
      w.x < -32 ||
      tiles_find_colliding(tiles, { x: w.x, y: w.y, w: 32, h: 32 }) 
    end
  end

  def player_current_rect
    { x: player.x, y: player.y, w: player.size, h: player.size }
  end

  def available_brick_locations
    (0..19).to_a
      .product(0..11)
      .map do |(ordinal_x, ordinal_y)|
      { ordinal_x: ordinal_x,
        ordinal_y: ordinal_y,
        x: ordinal_x * 64,
        y: ordinal_y * 64,
        w: 64,
        h: 64 }
    end
  end

  def player
    state.player ||= args.state.new_entity :player
  end

  def weapons
    state.weapons ||= []
  end

  def enemies
    state.enemies
  end

  def player_next_dy
    player.dy + state.gravity + state.drag ** 2 * -1
  end

  def player_next_dx
    player.dx * 0.8
  end

  def player_next_rect
    player.rect.merge x: player.x + player_next_dx,
                      y: player.y + player_next_dy
  end

  def player_prev_rect
    player.rect.merge x: player.x - player.dx,
                      y: player.y - player.dy
  end

  def player_dir
    if player.is_right
      1
    else
      -1
    end
  end

  def player_shot
    x = if player.is_right 
      player.x + 50
    else
      player.x - 20
    end

    weapons << {
      x: x,
      y: player.y + 8,
      is_right: player.is_right,
    }
  end

  def player_jump
    return if player.action != :standing
    player.action = :jumping
    player.dy = state.player.jump_power
    current_frame = state.tick_count
    player.action_at = current_frame
  end

  def player_jump_increase_air_time
    return if player.action != :jumping
    return if player.action_at.elapsed_time >= player.jump_air_time
    player.dy += player.jump_increase_power
  end

  def tiles
    state.tiles
  end

  def tiles_find_colliding tiles, target
    tiles.find { |t| t.rect.intersect_rect? target }
  end

  def tiles_find &block
    tiles.find_all(&block)
  end
end

def tick args
  $game ||= Game.new
  $game.args = args
  $game.tick
end

$gtk.reset

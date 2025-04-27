# FrameTimer - single file library for dispalying frame timings in DragonRuby
class FrameTimer
  def initialize(graph_scale: 3, graph_width: 1280, graph_x: 0, graph_y: 0, graph_alpha: 200, start_disabled: false)
    @clear_next_tick = true
    @frame_start_time = 0
    @frame_end_time = 0
    @graph_scale = graph_scale
    @frame_index = 0
    @graph_width = graph_width
    @graph_height = 32 * graph_scale
    @graph_x = graph_x
    @graph_y = graph_y
    @graph_alpha = graph_alpha
    @disabled = $gtk.production? || start_disabled
  end

  def enable
    @clear_next_tick = true
    @disabled = false
    @frame_index = 0

    start_tick($args)
  end

  def disable
    @disabled = true
  end

  def toggle
    if @disabled
      enable
    else
      disable
    end
  end

  def start_tick(args)
    @frame_start_time = Time.now

    return if @disabled

    args.outputs[:frame_timing].clear_before_render = false
    args.outputs[:frame_timing].w = @graph_width
    args.outputs[:frame_timing].h = @graph_height
  end

  def end_tick(args)
    @frame_end_time = Time.now

    return if @disabled

    elapsed_time = @frame_end_time - @frame_start_time
    elapsed_ms = (elapsed_time * 1000).to_i
    color = { r: 0, g: 255, b: 0 }
    if elapsed_ms > 8 && elapsed_ms < 16
      color = { r: 255, g: 255, b: 0 }
    elsif elapsed_ms >= 16
      color = { r: 255, g: 0, b: 0 }
    end

    if @clear_next_tick
      args.outputs[:frame_timing].clear_before_render = true
      yellow_y = 8 * @graph_scale
      red_y = 16 * @graph_scale
      args.outputs[:frame_timing].lines << [
        { x: 0, y: yellow_y, x2: @graph_width, y2: yellow_y, r: 255, g: 255, b: 0, a: @graph_alpha },
        { x: 0, y: red_y, x2: @graph_width, y2: red_y, r: 255, g: 0, b: 0, a: @graph_alpha }
      ]
      @clear_next_tick = false
    end

    args.outputs[:frame_timing].lines << {
      x: @frame_index, y: 0,
      x2: @frame_index, y2: elapsed_ms * @graph_scale, **color, a: @graph_alpha
    }

    @frame_index += 1
    if @frame_index == @graph_width
      @clear_next_tick = true
      @frame_index = 0
    end

    args.outputs.primitives << {
      x: @graph_x, y: @graph_y, w: @graph_width, h: @graph_height, path: :frame_timing
    }
  end
end

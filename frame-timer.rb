# FrameTimer - single file library for displaying frame timings in DragonRuby
class FrameTimer
  def initialize(graph_scale: 3, graph_alpha: 200, start_disabled: false)
    @clear_next_tick = true
    @frame_start_time = 0
    @frame_end_time = 0
    @graph_scale = graph_scale
    @frame_index = 0
    @graph_width = 1280
    @graph_height = 32 * graph_scale
    @graph_x = 0
    @graph_y = 0
    @graph_alpha = graph_alpha
    @disabled = $gtk.production? || start_disabled
    @buffers = [:graph1, :graph2]

    # collection and index for frame spans
    @frame_spans = Array.new(@graph_width) { { children: {} } }
    @frame_span_index = 0
    @show_span_profiles = false
    @span_name_stack = []
    @span_collecter_stack = []
  end

  def toggle_span_profiles
    @show_span_profiles = !@show_span_profiles
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

    @frame_spans[@frame_index] = { children: {} }
    @span_collecter_stack = [@frame_spans[@frame_index]]

    return if @disabled

    args.outputs[@buffers[0]].set(clear_before_render: false, w: @graph_width h: @graph_height)
    args.outputs[@buffers[1]].set(clear_before_render: false, w: @graph_width h: @graph_height)
  end

  def end_tick(args)
    @frame_end_time = Time.now

    return if @disabled

    if @show_span_profiles
      $outputs.primitives << {
        x: 0, y: 0, w: 1280, h: 720, path: :solid,
        a: 240, r: 30, g: 40, b: 40
      }
      render_span_profiles()
    else
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

      $outputs[@buffers[0]].clear_before_render = true
      $outputs[@buffers[0]].primitives << {
        x: -1, y: 0, w: @graph_width, h: @graph_height, path: @buffers[1],
      }

      $outputs[@buffers[0]].lines << {
        x: 1279, y: 0,
        x2: 1279, y2: elapsed_ms * @graph_scale, **color, a: 255
      }

      @buffers[0], @buffers[1] = @buffers[1], @buffers[0]

      @frame_index += 1
      if @frame_index == @graph_width
        @clear_next_tick = true
        @frame_index = 0
      end
    end

    args.outputs.primitives << {
      x: @graph_x, y: @graph_y, w: @graph_width, h: @graph_height, path: @buffers[1], a: @graph_alpha
    }
  end

  def render_span_profiles
    # check whether the mouse in in a valid span
    # if so, render the span_graph
    mouse_x = $inputs.mouse.x

    # translate mouse position to position in spans array
    span_index = (mouse_x + @frame_index) % 1280
    render_span_graph(span_index)
  end

  def render_span_graph(span_position)

    span_to_render = @frame_spans[span_position]

    prims = []
    parent = {x: 300, y: 100, text_x: 20, text_y: 700}

    prims << {
      x: 0, y: 50, w: 300, h: 670, path: :solid, r: 30, g: 40, b: 40
    }

    # text column headers
    prims << {r: 250, g: 250, b: 230, text: "Name", x: 20, y: 700, size_enum: -3, aligntment_enum: 2}
    prims << {r: 200, g: 200, b: 220, text: "%", x:  265, y: 700, size_enum: -3, aligntment_enum: 2}
    prims << {r: 200, g: 200, b: 220, text: "ms", x:  235, y: 700, size_enum: -3, aligntment_enum: 2}

    recurse_span_graph(prims, span_to_render, parent)

    $outputs.primitives << prims
  end

  def recurse_span_graph(prims, curr_node, parent)
    new_x = parent.x
    new_y = parent.y
    text_x = parent.text_x
    text_y = parent.text_y
    graph_height = 40
    text_indent = 13
    text_height = 20
    text_line_height = 5
    text_percent_column_x = 265
    text_ms_column_x = 235
    text_size = -5

    curr_node.children.each do |name, child|
      time_ms = child.time * 1000.0
      percent = (time_ms / 16.0) * 100
      r = 255 / 16 * time_ms
      g = 255 - (255 / 16 * time_ms)
      width = 950.0 / 16.0 * (time_ms)
 
      child_rect = {
        x: new_x, y: new_y + graph_height,
        w: width, h: graph_height,
        path: :solid, r: r, g: g, b: 0,
        text_x: text_x + text_indent, text_y: text_y - text_height,
      }
      new_x += width
      text_y -= text_height

      prims << child_rect
      prims << child_rect.merge(r: 0, g: 0, b: 0, primitive_marker: :border)
      prims << child_rect.merge(r: 0, g: 0, b: 0, primitive_marker: :label, text: "#{name}: #{time_ms.to_sf}", vertical_alignment_enum: 0, size_enum: text_size)

      # textual dump
      prims << {r: 200, g: 200, b: 200, text: "#{name}", x: text_x, y: text_y, size_enum: text_size}
      prims << {r: 200, g: 200, b: 200, text: sprintf("%.1f", time_ms), x: text_ms_column_x, y: text_y, size_enum: text_size}
      prims << {r: r, g: g, b: 0, text: sprintf("%.1f\%", percent), x: text_percent_column_x, y: text_y, size_enum: text_size, aligntment_enum: 2}
      prims << {r: 60, g: 60, b: 70, x: 0, y: text_y + text_line_height, x2: 300, y2: text_y + text_line_height}

      # if this node has children, render those above this one
      if child.size != 1
        recurse_span_graph(prims, child, child_rect)
      end
    end
  end

  def span(name, &block)

    @span_name_stack.push(name)

    start_time = Time.now

    block.call

    end_time = Time.now
    time_diff = end_time - start_time

    if !@show_span_profiles
      add_time_to_span_graph(name, time_diff)
    end

    @span_name_stack.pop()
  end

  def add_time_to_span_graph(name, elapsed_time)

    check_node = @frame_spans[@frame_index]
    span_node = nil

    @span_name_stack.each do |span_name|

      span_node = check_node[:children][span_name]
      if span_node.nil?
        span_node = { time: 0, children: {} }
        check_node[:children][span_name] = span_node
      end

      check_node = span_node
    end

    span_node[:time] += elapsed_time

  end
end

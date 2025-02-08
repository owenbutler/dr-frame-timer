# DR Frame Timer

Single file library intended for use with [DragonRuby](https://dragonruby.org/).

DR Frame Timer shows a small graph of elapsed frame time, over time.

[screenshot]

## Installation

Preferred install is via DragonRuby builtin [download_stb_rb](https://docs.dragonruby.org/#-----download_stb_rb(_raw)-)

First, download the lib using the above method, in the DragonRuby Console:

```
$gtk.download_stb_raw "https://github.com/owenbutler/dr-frame-timer/blob/main/frame-timer.rb" "lib/frame-timer.rb"
```

By default, this will download the lib to `lib/frame-timer.rb`

Include the following in your `main.rb`:

```
require 'lib/frame-timer.rb'
```

## Usage

Minimal example:

```ruby
require 'lib/frame-timer.rb'

$frame-timer = FrameTimer.new

def tick args
  $frame_timer.start_tick(args)

  # ...

  $frame_timer.end_tick(args)
end
```

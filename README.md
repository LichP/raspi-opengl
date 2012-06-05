raspi-opengl
============

An interface to the Raspberry Pi OpenGL libraries for Ruby using FFI.

Status
------

Initial Ruby FFI implementations of bcm_host.h, EGL/egl.h, and GLES/gl.h are
done, and a utility class RaspiGL has been implemented. In the `examples`
directory you can find `hello_triangle_original.rb`, which is a straight port
of the C hello_triangle example, and `hello_triangle_rubified.rb`, which is
written to use the RaspiGL utility class.

Usage
-----

Something like this:

```ruby
require 'raspigl'   # Will need load path mod until the Gem is done

class MyProject < RaspiGL
  def setup
    # Insert code to setup your models, load textures, etc
  end

  def tick
    # Called by the program loop - insert code to redraw your scene here
  end
end

my_project= Myproject.new
my_project.start
```

See `examples/hello_triangle_rubified.rb` to see this in action.

Todo
----

  * Gemspec
  * GLES2
  * More examples

--
Phil Stewart
June 2012

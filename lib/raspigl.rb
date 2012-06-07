require 'ffi'
require File.join(File.dirname(__FILE__), 'raspigl', 'bcm_host')
require File.join(File.dirname(__FILE__), 'raspigl', 'egl')
require File.join(File.dirname(__FILE__), 'raspigl', 'gles')

class RaspiGL
  class RaspiGLError < StandardError; end

  include BCMHost, EGL, GLES
  
  @@default_opts = {
    main_loop_sleep:          0.005,
    default_background_color: [0.0, 0.0, 0.0, 0.0],
    egl_config_attributes:    [
      EGL_RED_SIZE,     8,
      EGL_GREEN_SIZE,   8,
      EGL_BLUE_SIZE,    8,
      EGL_ALPHA_SIZE,   8,
      EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
      EGL_NONE
    ]
  }
  
  # Attribute readers
  [:opts, :time, :counter, :last_second, :fps, :events].each do |sym|
    define_method(sym) { self.instance_variable_get(:"@_#{sym}") || nil }
  end

  def initialize(opts = {})
    @_opts = @@default_opts.merge(opts)
    checkopts
    
    # Set up the Raspberry Pi OpenGL environment
    init_opengl

    # Do user setup
    setup

    self
  end

  # User setup. This method is empty by default: override it in your class
  # to set up models, load textures, and perform any other tasks which need
  # doing before starting the main loop.
  def setup
  end

  # Starts the main loop. Call this method when you've set everything up
  # and your ready to start rendering graphics.
  def start
    trap("INT") { $raspigl_terminate = true }
    at_exit { self.cleanup } 

    while !$raspigl_terminate do
      sleep @_opts[:main_loop_sleep]
      self.loop
    end
  end
  
  # The loop method provides the main loop. The default implementation does
  # some housekeeping, invokes #tick, then redraws the screen using
  # eglSwapBuffers.
  def loop
    @_counter ||= 0
    @_last_second ||= Time.now.to_i
    @_fps ||= 0
    @_events ||= {}
    @_events.clear

    @_counter += 1
    @_time = Time.now
    if (@_time.to_i - @_last_second) >= 1
      @_last_second = @_time.to_i
      @_fps = @_counter
      @_counter = 0
      @_events[:new_second] = true
    end

    self.tick

    eglSwapBuffers(@_display, @_surface)
  end

  # Called once on every iteration of the main loop. This method is empty
  # by default: override it in your class to redraw the screen, etc.
  def tick
  end

  # Return the width of the OpenGL surface. This can be specified when
  # initializing by passing the :width option. Defaults to the screen
  # width.
  #  
  # @return width
  def width
    opts[:width] || @_screen_width || 0
  end
  
  # Return the height of the OpenGL surface. This can be specified when
  # initializing by passing the :height option. Defaults to the screen
  # height.
  #  
  # @return width
  def height
    opts[:height] || @_screen_height || 0
  end

  # Load a texture from a file into an OpenGL compatible buffer
  #
  # @param [String] filename of texture file to load
  # @return [FFI::Pointer] loaded texture data ready for use with OpenGL
  #         function calls
  def load_texture_from_file(pathspec)
    data = File.open(File.join(pathspec), "rb").read
    load_texture_from_string(data)
  end
  
  # Load a texture from a string into an OpenGL compatible buffer
  #
  # @param [String] string containing texture data
  # @return [FFI::Pointer] loaded texture data ready for use with OpenGL
  #         function calls
  def load_texture_from_string(data)
    buffer = FFI::MemoryPointer.new(:char, data.size)
    buffer.put_bytes(0, data)
    buffer
  end
  
  # Load an array of coordinates into memory
  #
  # @param [Array] array containing coordinates as floats or integers
  # @return [FFI::Pointer] loaded coordinates ready for use with OpenGL
  #         fucntion calls
  def load_coords_from_array(coords)
    case coords.first
      when Fixnum
        coord_pointer = FFI::MemoryPointer.new(:int, coords.length)
        coord_pointer.write_array_of_int(coords)
      when Float
        coord_pointer = FFI::MemoryPointer.new(:float, coords.length)
        coord_pointer.write_array_of_float(coords)
    end
    coord_pointer
  end
  
  protected
  
  # This method does the heavy lifting of setting up the Raspberry Pi
  # OpenGL environment.
  def init_opengl
    bcm_host_init
    
    # Get an EGL display connection
    @_display = eglGetDisplay(EGL_DEFAULT_DISPLAY)
    assert_egl(@_display != EGL_NO_DISPLAY,
               "eglGetDisplay error: retval = #{@_display}")
    
    # Initialize the EGL display connection
    result = eglInitialize(@_display, nil, nil)
    assert_egl(result != EGL_FALSE,
               "eglInitialize error: retval = #{result}")
    
    # Get an appropriate EGL frame buffer configuration
    egl_config_pointer = FFI::MemoryPointer.new(:pointer)
    result = eglChooseConfig(@_display,
                             self.egl_config_attributes,
                             egl_config_pointer,
                             1,
                             FFI::MemoryPointer.new(:int))
    assert_egl(result != EGL_FALSE,
               "eglChooseConfig error: retval = #{result}")
    @_egl_config = egl_config_pointer.get_pointer(0)
    
    # Create an EGL rendering context
    @_context = eglCreateContext(@_display, @_egl_config, EGL_NO_CONTEXT, nil)
    assert_egl(@_context != EGL_NO_CONTEXT,
               "eglCreateContext error: retval = #{@_context}")
    
    # Determine screen dimensions
    screen_width_pointer  = FFI::MemoryPointer.new(:int)
    screen_height_pointer = FFI::MemoryPointer.new(:int)

    result = graphics_get_display_size(0, screen_width_pointer, screen_height_pointer)
    assert(result >= 0, "graphics_get_display_size error: retval = #{result}")

    @_screen_width  = screen_width_pointer.read_int
    @_screen_height = screen_height_pointer.read_int
    
    # Do VC dispmanx work to setup native window
    dst_rect = VC_RECT_T.new
    src_rect = VC_RECT_T.new
    
    dst_rect[:x] = 0
    dst_rect[:y] = 0
    dst_rect[:width]  = self.width
    dst_rect[:height] = self.height

    src_rect[:x] = 0
    src_rect[:y] = 0
    src_rect[:width]  = self.width  << 16
    src_rect[:height] = self.height << 16

    dispman_display = vc_dispmanx_display_open(0)
    dispman_update =  vc_dispmanx_update_start(0)
    
    dispman_element = vc_dispmanx_element_add(dispman_update,
                                              dispman_display,
                                              0,
                                              dst_rect.to_ptr,
                                              0,
                                              src_rect.to_ptr,
                                              DISPMANX_PROTECTION_NONE,
                                              FFI::Pointer.new(:void, 0),
                                              FFI::Pointer.new(:void, 0),
                                              :DISPMANX_NO_ROTATE)

    native_window = EGL_DISPMANX_WINDOW_T.new
    native_window[:element] = dispman_element
    native_window[:width]   = self.width
    native_window[:height]  = self.height

    vc_dispmanx_update_submit_sync(dispman_update)

    # Create an EGL window surface
    @_surface = eglCreateWindowSurface(@_display, @_egl_config, native_window.to_ptr, nil)
    assert_egl(@_surface != EGL_NO_SURFACE,
               "eglCreateWindowSurface error: retval = #{@_surface}")

    # Connect the context to the surface
    result = eglMakeCurrent(@_display, @_surface, @_surface, @_context)
    assert_egl(result != EGL_FALSE,
               "eglMakeCurrent error: retval = #{result}")

    # Set background colour and clear buffers
    glClearColor(*opts[:default_background_color])
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glShadeModel(GL_FLAT)
    
    # Enable back face culling.
    glEnable(GL_CULL_FACE)
  end
  
  def cleanup
    # Clear screen
    glClear(RaspiGL::GLES::GL_COLOR_BUFFER_BIT)
    eglSwapBuffers(@_display, @_surface)

    # Release OpenGL resources
    eglMakeCurrent(@_display,
                    EGL_NO_SURFACE,
                    EGL_NO_SURFACE,
                    EGL_NO_CONTEXT)
    eglDestroySurface(@_display, @_surface)
    eglDestroyContext(@_display, @_context)
    eglTerminate(@_display)
  end
  
  def assert(condition, message = nil)
    unless condition
      raise RaspiGLError, message
    end
  end
  
  def assert_egl(condition, message = nil)
    egl_message = "eglGetError returned 0x%x" % eglGetError()
    if message
      message = "#{message} (#{egl_message})"
    else
      message = egl_message
    end
    assert(condition, message)
  end
  
  def checkopts
    if @_opts[:egl_config_attributes].last != EGL_NONE
      warn("opts[:egl_config_attributes] not terminated with EGL_NONE, appending.")
      @_opts[:egl_config_attributes] << EGL_NONE
    end
  end
  
  def egl_config_attributes
    @_egl_conf_attrs ||= egl_config_attributes!
  end
  
  def egl_config_attributes!
    egl_conf_attrs = FFI::MemoryPointer.new(:int,
        opts[:egl_config_attributes].length)
    egl_conf_attrs.write_array_of_int(opts[:egl_config_attributes])
    egl_conf_attrs
  end
end

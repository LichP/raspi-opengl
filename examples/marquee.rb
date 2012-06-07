#!/usr/bin/ruby1.9.1
#
# Demonstrate a marquee effect using RMagick to render text

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'raspigl'
require 'RMagick'

class Marquee < RaspiGL

  def setup
    marquee_text = "This is a marquee demo"
    
    # Setup GL for 2D working
    self.setup_gl_2d

    # First make an image containing the text with RMagick 
    # and convert it in to a texture buffer
    marquee_image = make_marquee_image(marquee_text)
    marquee_texture_buffer = magick_to_tex_buf(marquee_image)
    test_texture_buffer = load_texture_from_file(File.join(RaspiGL::VC_PATH, "src/hello_pi/hello_triangle/Djenne_128_128.raw"))
    
    # For convenience we get the width and height of the texture in to some
    # more conveniently named variables
    marquee_width  = marquee_image.columns
    marquee_height = marquee_image.rows
    
    # Next, setup some GL texture names. We'll allow for two textures, one
    # for the marquee, and another for FPS.
    @textures = FFI::MemoryPointer.new(:uint, 2)
    glGenTextures(2, @textures)
    
    # Now load the marquee texture to GL
    glBindTexture(GL_TEXTURE_2D, @textures[0])
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, marquee_width, marquee_height, 0,
                 GL_RGB, GL_UNSIGNED_BYTE, marquee_texture_buffer)
#    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 128, 128, 0,
#                 GL_RGB, GL_UNSIGNED_BYTE, test_texture_buffer)

    # These parameters control how the texture is minified and magnified.
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
    
    # Next we set up a quad to paint our texture on to. We need two sets of
    # coordinates: one for the quad's vertices, (i.e. where the quad gets
    # placed in the 2D world), and one for the texture (i.e. whereabouts
    # on the quad do we paint the texture)
    @quad_width = marquee_width * 4
    @quad_height = marquee_height * 4
    @quad_coords = load_coords_from_array([
      0, 0,
      0, @quad_height,
      @quad_width, 0,
      @quad_width, @quad_height
    ])
    @texture_coords = load_coords_from_array([
      0.0, 0.0,
      0.0, 1.0,
      1.0, 0.0,
      1.0, 1.0
    ])
    
    # Tell GL where to find our vertex and texture coords    
    glVertexPointer(2, GL_FIXED, 0, @quad_coords)
    glTexCoordPointer(2, GL_FLOAT, 0, @texture_coords)

    # Translate to middle of screen
    glTranslatex(0, (height - @quad_height) / 2, 0)
    
    # Set marquee step and position tracker
    @step = 4
    @pos = 0
  end
  
  def setup_gl_2d
    # Set the viewport
    glViewport(0, 0, width, height)
    
    # Set up a 2D projection
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
    glOrthox(0, width, height, 0, 0, 1)
    glMatrixMode(GL_MODELVIEW)
    
    # Disable the depth buffer
    glDisable(GL_DEPTH_TEST)
    
    # Clear the screen to solid black
    glClearColor(0.0, 0.0, 0.0, 1.0)
    glClear(GL_COLOR_BUFFER_BIT)

    # Enable texturing
    glEnable(GL_TEXTURE_2D)

    # Tell GL that we want to load vertex and texture coords
    # from the client side (i.e. our code)
    glEnableClientState(GL_VERTEX_ARRAY)
    glEnableClientState(GL_TEXTURE_COORD_ARRAY)
  end
  
  def make_marquee_image(marquee_text)
    marquee_image = Magick::Image.new(1024, 128) do
      self.background_color = 'black'
    end
    
    text = Magick::Draw.new
    text.font_family ='helvetica'
    text.pointsize = 64
    text.gravity = Magick::CenterGravity
    
    text.annotate(marquee_image, 0,0,0,0, marquee_text) do
      self.fill = 'green'
    end
    
    marquee_image
  end
  
  def magick_to_tex_buf(image)
    blob = image.to_blob do
      self.depth = 8
      self.format = "RGB"
    end
    load_texture_from_string(blob)
  end
  
  def redraw
    glClear(GL_COLOR_BUFFER_BIT)
    glTexEnvx(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE)
    
    # Bind the texture
    glBindTexture(GL_TEXTURE_2D, @textures[0])
    
    # Draw the quad
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4)
    
    # Translate by the step amount
    glTranslatex(-@step, 0, 0)
    @pos -= @step
    if @pos < -@quad_width
      # Reset marquee position
      @pos += @quad_width * 2
      glTranslatex(@quad_width * 2, 0, 0)
    end
  end
   
  def tick
    if events[:new_second]
      puts "FPS: #{fps}"
    end
   
    redraw
  end
end

marquee = Marquee.new
marquee.start

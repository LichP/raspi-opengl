#!/usr/bin/ruby1.9.1
#
# A rotating cube rendered with OpenGL|ES. Three images used as textures on the cube faces.

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'raspigl'
require File.join(File.dirname(__FILE__), 'cube_texture_and_coords.rb')

class Cube < RaspiGL
  IMAGE_SIZE = 128

  def setup
    self.init_model_proj
    self.reset_model
    self.init_textures
  end
  
  def tick
    if events[:new_second]
      puts "FPS: #{fps}"
    end
    self.update_model
    self.redraw_scene
  end

  def init_model_proj
    nearp = 1.0
    farp = 500.0
    hht = 0.0
    hwd = 0.0

    glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST)

    glViewport(0, 0, width, height)

    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()

    hht = nearp * Math.tan(45.0 / 2.0 / 180.0 * Math::PI)
    hwd = hht * width / height

    glFrustumf(-hwd, hwd, -hht, hht, nearp, farp)

    glEnableClientState(GL_VERTEX_ARRAY)
    glVertexPointer(3, GL_BYTE, 0, $quadx)

    glEnableClientState(GL_COLOR_ARRAY)
    glColorPointer(4, GL_FLOAT, 0, $colorsf)
  end
  
  def reset_model
    # reset model position
    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()
    glTranslatef(0.0, 0.0, -50.0)

    # reset model rotation
    @rot_angle_x = 45.0
    @rot_angle_y = 30.0
    @rot_angle_z = 0.0

    @rot_angle_x_inc = 0.5
    @rot_angle_y_inc = 0.5
    @rot_angle_z_inc = 0.0

    @distance = 40.0
    @distance_inc = 0.0
  end

  def init_textures
    # load three texture buffers but use them on six OGL|ES texture surfaces
    self.load_tex_images
    @tex = FFI::MemoryPointer.new(:uint, 6)
    glGenTextures(6, @tex)

    # setup first texture
    glBindTexture(GL_TEXTURE_2D, @tex[0])
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, IMAGE_SIZE, IMAGE_SIZE, 0,
                 GL_RGB, GL_UNSIGNED_BYTE, @tex_buf1)
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)

    # setup second texture - reuse first image
    glBindTexture(GL_TEXTURE_2D, @tex[1])
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, IMAGE_SIZE, IMAGE_SIZE, 0,
                 GL_RGB, GL_UNSIGNED_BYTE, @tex_buf1)
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)

    # third texture
    glBindTexture(GL_TEXTURE_2D, @tex[2])
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, IMAGE_SIZE, IMAGE_SIZE, 0,
                 GL_RGB, GL_UNSIGNED_BYTE, @tex_buf2)
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)

    # fourth texture  - reuse second image
    glBindTexture(GL_TEXTURE_2D, @tex[3])
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, IMAGE_SIZE, IMAGE_SIZE, 0,
                 GL_RGB, GL_UNSIGNED_BYTE, @tex_buf2)
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)

    # fifth texture
    glBindTexture(GL_TEXTURE_2D, @tex[4]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, IMAGE_SIZE, IMAGE_SIZE, 0,
                 GL_RGB, GL_UNSIGNED_BYTE, @tex_buf3)
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)

    # sixth texture  - reuse third image
    glBindTexture(GL_TEXTURE_2D, @tex[5])
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, IMAGE_SIZE, IMAGE_SIZE, 0,
                 GL_RGB, GL_UNSIGNED_BYTE, @tex_buf3)
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)

    # setup overall texture environment
    glTexCoordPointer(2, GL_FLOAT, 0, $texCoords)
    glEnableClientState(GL_TEXTURE_COORD_ARRAY)
  end

  def load_tex_images
    @tex_buf1 = load_texture_from_file(File.join(RaspiGL::VC_PATH, "src/hello_pi/hello_triangle/Lucca_128_128.raw"))
    @tex_buf2 = load_texture_from_file(File.join(RaspiGL::VC_PATH, "src/hello_pi/hello_triangle/Djenne_128_128.raw"))
    @tex_buf3 = load_texture_from_file(File.join(RaspiGL::VC_PATH, "src/hello_pi/hello_triangle/Gaudi_128_128.raw"))
  end

  def update_model
    # update position
    @rot_angle_x = inc_and_wrap_angle(@rot_angle_x, @rot_angle_x_inc)
    @rot_angle_y = inc_and_wrap_angle(@rot_angle_y, @rot_angle_y_inc)
    @rot_angle_z = inc_and_wrap_angle(@rot_angle_z, @rot_angle_z_inc)
    @distance    = inc_and_clip_distance(@distance, @distance_inc)

    glLoadIdentity()
    # move camera back to see the cube
    glTranslatef(0.0, 0.0, -@distance)

    # Rotate model to new position
    glRotatef(@rot_angle_x, 1.0, 0.0, 0.0);
    glRotatef(@rot_angle_y, 0.0, 1.0, 0.0);
    glRotatef(@rot_angle_z, 0.0, 0.0, 1.0);
  end

  def inc_and_wrap_angle(angle = 0.0, angle_inc = 0.0)
    angle += angle_inc

    if (angle >= 360.0)
      angle -= 360.0
    elsif (angle <= 0)
      angle += 360.0
    end

    angle
  end

  def inc_and_clip_distance(distance = 0.0, distance_inc = 0.0)
    distance += distance_inc

    if (distance >= 120.0)
      distance = 120.0
    elsif (distance <= 40.0)
      distance = 40.0
    end

    distance
  end

  
  def redraw_scene
    # Start with a clear screen
    glClear(GL_COLOR_BUFFER_BIT)
    glMatrixMode(GL_MODELVIEW)

    glEnable(GL_TEXTURE_2D)
    glTexEnvx(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE)

    # Draw first (front) face:
    # Bind texture surface to current vertices
    glBindTexture(GL_TEXTURE_2D, @tex[0])

    # Need to rotate textures - do this by rotating each cube face
    glRotatef(270.0, 0.0, 0.0, 1.0)  # front face normal along z axis

    # draw first 4 vertices
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4)

    # same pattern for other 5 faces - rotation chosen to make image orientation 'nice'
    glBindTexture(GL_TEXTURE_2D, @tex[1])
    glRotatef(90.0, 0.0, 0.0, 1.0 )  # back face normal along z axis
    glDrawArrays(GL_TRIANGLE_STRIP, 4, 4)

    glBindTexture(GL_TEXTURE_2D, @tex[2])
    glRotatef(90.0, 1.0, 0.0, 0.0 )  # left face normal along x axis
    glDrawArrays(GL_TRIANGLE_STRIP, 8, 4)

    glBindTexture(GL_TEXTURE_2D, @tex[3])
    glRotatef(90.0, 1.0, 0.0, 0.0 )  # right face normal along x axis
    glDrawArrays(GL_TRIANGLE_STRIP, 12, 4)

    glBindTexture(GL_TEXTURE_2D, @tex[4])
    glRotatef(270.0, 0.0, 1.0, 0.0 )  # top face normal along y axis
    glDrawArrays(GL_TRIANGLE_STRIP, 16, 4)

    glTexEnvx(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);

    glBindTexture(GL_TEXTURE_2D, @tex[5])
    glRotatef(90.0, 0.0, 1.0, 0.0 )  # bottom face normal along y axis
    glDrawArrays( GL_TRIANGLE_STRIP, 20, 4)

    glDisable(GL_TEXTURE_2D)
  end
end

cube = Cube.new
cube.start

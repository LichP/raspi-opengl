#!/usr/bin/ruby1.9.1
#
# Original C implementation Copyright (c) 2012 Broadcom Europe Ltd
# Ruby translation Copyright (c) 2012 Phil Stewart
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#
# A rotating cube rendered with OpenGL|ES. Three images used as textures on the cube faces.

$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'raspigl/common'
require 'raspigl/bcm_host'
require 'raspigl/egl'
require 'raspigl/gles'
require './cube_texture_and_coords.rb'

CubeState = Struct.new(
  :screen_width,
  :screen_height,
  :display,
  :surface,
  :context,
  :tex,
  :rot_angle_x_inc,
  :rot_angle_y_inc,
  :rot_angle_z_inc,
  :rot_angle_x,
  :rot_angle_y,
  :rot_angle_z,
  :distance,
  :distance_inc,
  :tex_buf1,
  :tex_buf2,
  :tex_buf3
)

IMAGE_SIZE = 128

def assert(condition, message = nil)
  unless condition
    error_status = RaspiGL::EGL::eglGetError()
    raise "%s (eglGetError returned 0x%x)" % [message, error_status]
  end
end

def init_ogl(state)
  success = 0
  result = 0
  num_config = FFI::MemoryPointer.new(:int)
  
  nativewindow = RaspiGL::EGL::EGL_DISPMANX_WINDOW_T.new

  dispman_element = 0
  dispman_display = 0
  dispman_update = 0
  dst_rect = RaspiGL::BCMHost::VC_RECT_T.new
  src_rect = RaspiGL::BCMHost::VC_RECT_T.new
  
  attribute_list = FFI::MemoryPointer.new(:int, 11)
  attribute_list.write_array_of_int([
    RaspiGL::EGL::EGL_RED_SIZE, 8,
    RaspiGL::EGL::EGL_GREEN_SIZE, 8,
    RaspiGL::EGL::EGL_BLUE_SIZE, 8,
    RaspiGL::EGL::EGL_ALPHA_SIZE, 8,
    RaspiGL::EGL::EGL_SURFACE_TYPE, RaspiGL::EGL::EGL_WINDOW_BIT,
    RaspiGL::EGL::EGL_NONE
  ])
  
  config = FFI::MemoryPointer.new(:pointer)
  
  # get an EGL display connection
  state.display = RaspiGL::EGL.eglGetDisplay(RaspiGL::EGL::EGL_DEFAULT_DISPLAY)
  assert(state.display != RaspiGL::EGL::EGL_NO_DISPLAY,
         "eglGetDisplay error: got state.display = #{state.display}")

  # initialize the EGL display connection
  result = RaspiGL::EGL.eglInitialize(state.display, nil, nil)
  assert(RaspiGL::EGL::EGL_FALSE != result,
         "eglInitialize error: got result = #{result}")

  # get an appropriate EGL frame buffer configuration
  result = RaspiGL::EGL.eglChooseConfig(state.display, attribute_list, config, 1, num_config)
  assert(RaspiGL::EGL::EGL_FALSE != result,
         "eglChooseConfig error: got result = #{result}")
  config = config.get_pointer(0)

  # create an EGL rendering context
  state.context = RaspiGL::EGL::eglCreateContext(state.display, config, RaspiGL::EGL::EGL_NO_CONTEXT, nil)
  assert(state.context != RaspiGL::EGL::EGL_NO_CONTEXT,
         "eglCreateContext error: got state.context = #{state.context}")

  # create an EGL window surface
  screen_width = FFI::MemoryPointer.new(:int)
  screen_height = FFI::MemoryPointer.new(:int)

  success = RaspiGL::BCMHost.graphics_get_display_size(0, screen_width, screen_height)
  assert(success >= 0, "graphics_get_display_size error: got success = #{success}")

  state.screen_width = screen_width.read_int
  state.screen_height = screen_height.read_int
  
  puts "Got dimensions: #{state.screen_width}x#{state.screen_height}"

  dst_rect[:x] = 0;
  dst_rect[:y] = 0;
  dst_rect[:width] = state.screen_width;
  dst_rect[:height] = state.screen_height;

  src_rect[:x] = 0;
  src_rect[:y] = 0;
  src_rect[:width] = state.screen_width << 16;
  src_rect[:height] = state.screen_height << 16;

  dispman_display = RaspiGL::BCMHost.vc_dispmanx_display_open(0)
  dispman_update = RaspiGL::BCMHost.vc_dispmanx_update_start(0)

  dispman_element = RaspiGL::BCMHost.vc_dispmanx_element_add(
    dispman_update,
    dispman_display,
    0,
    dst_rect.to_ptr,
    0,
    src_rect.to_ptr,
    RaspiGL::BCMHost::DISPMANX_PROTECTION_NONE,
    FFI::Pointer.new(:void, 0),
    FFI::Pointer.new(:void, 0),
    :DISPMANX_NO_ROTATE
  )

  nativewindow[:element] = dispman_element
  nativewindow[:width] = state.screen_width
  nativewindow[:height] = state.screen_height
  RaspiGL::BCMHost.vc_dispmanx_update_submit_sync(dispman_update)

  state.surface = RaspiGL::EGL.eglCreateWindowSurface(state.display, config, nativewindow.to_ptr, nil)
  assert(state.surface != RaspiGL::EGL::EGL_NO_SURFACE,
         "eglCreateWindowSurface error: got state.surface = #{state.surface}")

  # connect the context to the surface
  result = RaspiGL::EGL.eglMakeCurrent(state.display, state.surface, state.surface, state.context)
  assert(RaspiGL::EGL::EGL_FALSE != result,
         "eglMakeCurrent error: got result = #{result}")
  
  RaspiGL::GLES.glClearColor(0.15, 0.25, 0.35, 1.0)
  RaspiGL::GLES.glClear(RaspiGL::GLES::GL_COLOR_BUFFER_BIT)
  RaspiGL::GLES.glClear(RaspiGL::GLES::GL_DEPTH_BUFFER_BIT)
  RaspiGL::GLES.glShadeModel(RaspiGL::GLES::GL_FLAT)

  # Enable back face culling.
  RaspiGL::GLES.glEnable(RaspiGL::GLES::GL_CULL_FACE)
end

def init_model_proj(state)
  nearp = 1.0
  farp = 500.0
  hht = 0.0
  hwd = 0.0

  RaspiGL::GLES.glHint(RaspiGL::GLES::GL_PERSPECTIVE_CORRECTION_HINT, RaspiGL::GLES::GL_NICEST)

  RaspiGL::GLES.glViewport(0, 0, state.screen_width, state.screen_height)

  RaspiGL::GLES.glMatrixMode(RaspiGL::GLES::GL_PROJECTION)
  RaspiGL::GLES.glLoadIdentity()

  hht = nearp * Math.tan(45.0 / 2.0 / 180.0 * Math::PI)
  hwd = hht * state.screen_width / state.screen_height

  RaspiGL::GLES.glFrustumf(-hwd, hwd, -hht, hht, nearp, farp)

  RaspiGL::GLES.glEnableClientState(RaspiGL::GLES::GL_VERTEX_ARRAY)
  RaspiGL::GLES.glVertexPointer(3, RaspiGL::GLES::GL_BYTE, 0, $quadx)

  RaspiGL::GLES.glEnableClientState( RaspiGL::GLES::GL_COLOR_ARRAY)
  RaspiGL::GLES.glColorPointer(4, RaspiGL::GLES::GL_FLOAT, 0, $colorsf)

  reset_model(state)
end

def reset_model(state)
  # reset model position
  RaspiGL::GLES.glMatrixMode(RaspiGL::GLES::GL_MODELVIEW)
  RaspiGL::GLES.glLoadIdentity()
  RaspiGL::GLES.glTranslatef(0.0, 0.0, -50.0)

  # reset model rotation
  state.rot_angle_x = 45.0
  state.rot_angle_y = 30.0
  state.rot_angle_z = 0.0

  state.rot_angle_x_inc = 0.5
  state.rot_angle_y_inc = 0.5
  state.rot_angle_z_inc = 0.0

  state.distance = 40.0
  state.distance_inc = 0.0
end

def update_model(state)
  # update position
  state.rot_angle_x = inc_and_wrap_angle(state.rot_angle_x, state.rot_angle_x_inc)
  state.rot_angle_y = inc_and_wrap_angle(state.rot_angle_y, state.rot_angle_y_inc)
  state.rot_angle_z = inc_and_wrap_angle(state.rot_angle_z, state.rot_angle_z_inc)
  state.distance    = inc_and_clip_distance(state.distance, state.distance_inc)

  RaspiGL::GLES.glLoadIdentity()
  # move camera back to see the cube
  RaspiGL::GLES.glTranslatef(0.0, 0.0, -state.distance)

  # Rotate model to new position
  RaspiGL::GLES.glRotatef(state.rot_angle_x, 1.0, 0.0, 0.0);
  RaspiGL::GLES.glRotatef(state.rot_angle_y, 0.0, 1.0, 0.0);
  RaspiGL::GLES.glRotatef(state.rot_angle_z, 0.0, 0.0, 1.0);
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

def redraw_scene(state)
  # Start with a clear screen
  RaspiGL::GLES.glClear(RaspiGL::GLES::GL_COLOR_BUFFER_BIT)
  RaspiGL::GLES.glMatrixMode(RaspiGL::GLES::GL_MODELVIEW)

  RaspiGL::GLES.glEnable(RaspiGL::GLES::GL_TEXTURE_2D)
  RaspiGL::GLES.glTexEnvx(RaspiGL::GLES::GL_TEXTURE_ENV, RaspiGL::GLES::GL_TEXTURE_ENV_MODE, RaspiGL::GLES::GL_REPLACE)

  # Draw first (front) face:
  # Bind texture surface to current vertices
  RaspiGL::GLES.glBindTexture(RaspiGL::GLES::GL_TEXTURE_2D, state.tex[0])

  # Need to rotate textures - do this by rotating each cube face
  RaspiGL::GLES.glRotatef(270.0, 0.0, 0.0, 1.0)  # front face normal along z axis

  # draw first 4 vertices
  RaspiGL::GLES.glDrawArrays(RaspiGL::GLES::GL_TRIANGLE_STRIP, 0, 4)

  # same pattern for other 5 faces - rotation chosen to make image orientation 'nice'
  RaspiGL::GLES.glBindTexture(RaspiGL::GLES::GL_TEXTURE_2D, state.tex[1])
  RaspiGL::GLES.glRotatef(90.0, 0.0, 0.0, 1.0 )  # back face normal along z axis
  RaspiGL::GLES.glDrawArrays(RaspiGL::GLES::GL_TRIANGLE_STRIP, 4, 4)

  RaspiGL::GLES.glBindTexture(RaspiGL::GLES::GL_TEXTURE_2D, state.tex[2])
  RaspiGL::GLES.glRotatef(90.0, 1.0, 0.0, 0.0 )  # left face normal along x axis
  RaspiGL::GLES.glDrawArrays(RaspiGL::GLES::GL_TRIANGLE_STRIP, 8, 4)

  RaspiGL::GLES.glBindTexture(RaspiGL::GLES::GL_TEXTURE_2D, state.tex[3])
  RaspiGL::GLES.glRotatef(90.0, 1.0, 0.0, 0.0 )  # right face normal along x axis
  RaspiGL::GLES.glDrawArrays(RaspiGL::GLES::GL_TRIANGLE_STRIP, 12, 4)

  RaspiGL::GLES.glBindTexture(RaspiGL::GLES::GL_TEXTURE_2D, state.tex[4])
  RaspiGL::GLES.glRotatef(270.0, 0.0, 1.0, 0.0 )  # top face normal along y axis
  RaspiGL::GLES.glDrawArrays(RaspiGL::GLES::GL_TRIANGLE_STRIP, 16, 4)

  RaspiGL::GLES.glTexEnvx(RaspiGL::GLES::GL_TEXTURE_ENV, RaspiGL::GLES::GL_TEXTURE_ENV_MODE, RaspiGL::GLES::GL_MODULATE);

  RaspiGL::GLES.glBindTexture(RaspiGL::GLES::GL_TEXTURE_2D, state.tex[5])
  RaspiGL::GLES.glRotatef(90.0, 0.0, 1.0, 0.0 )  # bottom face normal along y axis
  RaspiGL::GLES.glDrawArrays( RaspiGL::GLES::GL_TRIANGLE_STRIP, 20, 4)

  RaspiGL::GLES.glDisable(RaspiGL::GLES::GL_TEXTURE_2D)

  RaspiGL::EGL.eglSwapBuffers(state.display, state.surface)
end

def init_textures(state)
  # load three texture buffers but use them on six OGL|ES texture surfaces
  load_tex_images(state)
  state.tex = FFI::MemoryPointer.new(:uint, 6)
  RaspiGL::GLES.glGenTextures(6, state.tex)

  # setup first texture
  RaspiGL::GLES.glBindTexture(RaspiGL::GLES::GL_TEXTURE_2D, state.tex[0])
  RaspiGL::GLES.glTexImage2D(RaspiGL::GLES::GL_TEXTURE_2D, 0, RaspiGL::GLES::GL_RGB,
                             IMAGE_SIZE, IMAGE_SIZE, 0,
                             RaspiGL::GLES::GL_RGB, RaspiGL::GLES::GL_UNSIGNED_BYTE,
                             state.tex_buf1)
  RaspiGL::GLES.glTexParameterf(RaspiGL::GLES::GL_TEXTURE_2D, RaspiGL::GLES::GL_TEXTURE_MIN_FILTER, RaspiGL::GLES::GL_NEAREST)
  RaspiGL::GLES.glTexParameterf(RaspiGL::GLES::GL_TEXTURE_2D, RaspiGL::GLES::GL_TEXTURE_MAG_FILTER, RaspiGL::GLES::GL_NEAREST)

  # setup second texture - reuse first image
  RaspiGL::GLES.glBindTexture(RaspiGL::GLES::GL_TEXTURE_2D, state.tex[1])
  RaspiGL::GLES.glTexImage2D(RaspiGL::GLES::GL_TEXTURE_2D, 0, RaspiGL::GLES::GL_RGB,
                             IMAGE_SIZE, IMAGE_SIZE, 0,
                             RaspiGL::GLES::GL_RGB, RaspiGL::GLES::GL_UNSIGNED_BYTE,
                             state.tex_buf1)
  RaspiGL::GLES.glTexParameterf(RaspiGL::GLES::GL_TEXTURE_2D, RaspiGL::GLES::GL_TEXTURE_MIN_FILTER, RaspiGL::GLES::GL_NEAREST)
  RaspiGL::GLES.glTexParameterf(RaspiGL::GLES::GL_TEXTURE_2D, RaspiGL::GLES::GL_TEXTURE_MAG_FILTER, RaspiGL::GLES::GL_NEAREST)

  # third texture
  RaspiGL::GLES.glBindTexture(RaspiGL::GLES::GL_TEXTURE_2D, state.tex[2])
  RaspiGL::GLES.glTexImage2D(RaspiGL::GLES::GL_TEXTURE_2D, 0, RaspiGL::GLES::GL_RGB,
                             IMAGE_SIZE, IMAGE_SIZE, 0,
                             RaspiGL::GLES::GL_RGB, RaspiGL::GLES::GL_UNSIGNED_BYTE,
                             state.tex_buf2)
  RaspiGL::GLES.glTexParameterf(RaspiGL::GLES::GL_TEXTURE_2D, RaspiGL::GLES::GL_TEXTURE_MIN_FILTER, RaspiGL::GLES::GL_NEAREST)
  RaspiGL::GLES.glTexParameterf(RaspiGL::GLES::GL_TEXTURE_2D, RaspiGL::GLES::GL_TEXTURE_MAG_FILTER, RaspiGL::GLES::GL_NEAREST)

  # fourth texture  - reuse second image
  RaspiGL::GLES.glBindTexture(RaspiGL::GLES::GL_TEXTURE_2D, state.tex[3])
  RaspiGL::GLES.glTexImage2D(RaspiGL::GLES::GL_TEXTURE_2D, 0, RaspiGL::GLES::GL_RGB,
                             IMAGE_SIZE, IMAGE_SIZE, 0,
                             RaspiGL::GLES::GL_RGB, RaspiGL::GLES::GL_UNSIGNED_BYTE,
                             state.tex_buf2)
  RaspiGL::GLES.glTexParameterf(RaspiGL::GLES::GL_TEXTURE_2D, RaspiGL::GLES::GL_TEXTURE_MIN_FILTER, RaspiGL::GLES::GL_NEAREST)
  RaspiGL::GLES.glTexParameterf(RaspiGL::GLES::GL_TEXTURE_2D, RaspiGL::GLES::GL_TEXTURE_MAG_FILTER, RaspiGL::GLES::GL_NEAREST)

  # fifth texture
  RaspiGL::GLES.glBindTexture(RaspiGL::GLES::GL_TEXTURE_2D, state.tex[4]);
  RaspiGL::GLES.glTexImage2D(RaspiGL::GLES::GL_TEXTURE_2D, 0, RaspiGL::GLES::GL_RGB,
                             IMAGE_SIZE, IMAGE_SIZE, 0,
                             RaspiGL::GLES::GL_RGB, RaspiGL::GLES::GL_UNSIGNED_BYTE,
                             state.tex_buf3)
  RaspiGL::GLES.glTexParameterf(RaspiGL::GLES::GL_TEXTURE_2D, RaspiGL::GLES::GL_TEXTURE_MIN_FILTER, RaspiGL::GLES::GL_NEAREST)
  RaspiGL::GLES.glTexParameterf(RaspiGL::GLES::GL_TEXTURE_2D, RaspiGL::GLES::GL_TEXTURE_MAG_FILTER, RaspiGL::GLES::GL_NEAREST)

  # sixth texture  - reuse third image
  RaspiGL::GLES.glBindTexture(RaspiGL::GLES::GL_TEXTURE_2D, state.tex[5])
  RaspiGL::GLES.glTexImage2D(RaspiGL::GLES::GL_TEXTURE_2D, 0, RaspiGL::GLES::GL_RGB,
                             IMAGE_SIZE, IMAGE_SIZE, 0,
                             RaspiGL::GLES::GL_RGB, RaspiGL::GLES::GL_UNSIGNED_BYTE,
                             state.tex_buf3)
  RaspiGL::GLES.glTexParameterf(RaspiGL::GLES::GL_TEXTURE_2D, RaspiGL::GLES::GL_TEXTURE_MIN_FILTER, RaspiGL::GLES::GL_NEAREST)
  RaspiGL::GLES.glTexParameterf(RaspiGL::GLES::GL_TEXTURE_2D, RaspiGL::GLES::GL_TEXTURE_MAG_FILTER, RaspiGL::GLES::GL_NEAREST)

  # setup overall texture environment
  RaspiGL::GLES.glTexCoordPointer(2, RaspiGL::GLES::GL_FLOAT, 0, $texCoords)
  RaspiGL::GLES.glEnableClientState(RaspiGL::GLES::GL_TEXTURE_COORD_ARRAY)
end

def load_tex_images(state)
  tex_file1 = File.open(File.join(RaspiGL::VC_PATH, "src/hello_pi/hello_triangle/Lucca_128_128.raw"), "rb").read
  tex_file2 = File.open(File.join(RaspiGL::VC_PATH, "src/hello_pi/hello_triangle/Djenne_128_128.raw"), "rb").read
  tex_file3 = File.open(File.join(RaspiGL::VC_PATH, "src/hello_pi/hello_triangle/Gaudi_128_128.raw"), "rb").read
  
  state.tex_buf1 = FFI::MemoryPointer.new(:char, tex_file1.size)
  state.tex_buf2 = FFI::MemoryPointer.new(:char, tex_file2.size)
  state.tex_buf3 = FFI::MemoryPointer.new(:char, tex_file3.size)

  state.tex_buf1.put_bytes(0, tex_file1)
  state.tex_buf2.put_bytes(0, tex_file2)
  state.tex_buf3.put_bytes(0, tex_file3)
end

# Function to be passed to atexit().
def exit_func(state)
  # clear screen
  RaspiGL::GLES.glClear(RaspiGL::GLES::GL_COLOR_BUFFER_BIT)
  RaspiGL::EGL.eglSwapBuffers(state.display, state.surface)

  # Release OpenGL resources
  RaspiGL::EGL.eglMakeCurrent(state.display,
                              RaspiGL::EGL::EGL_NO_SURFACE,
                              RaspiGL::EGL::EGL_NO_SURFACE,
                              RaspiGL::EGL::EGL_NO_CONTEXT)
  RaspiGL::EGL.eglDestroySurface(state.display, state.surface)
  RaspiGL::EGL.eglDestroyContext(state.display, state.context)
  RaspiGL::EGL.eglTerminate(state.display)

  # release texture buffers
  #free(state.tex_buf1)
  #free(state.tex_buf2)
  #free(state.tex_buf3)

  puts("\ncube closed")
end


$terminate = false

trap("INT") { $terminate = true }

def main
  RaspiGL::BCMHost.bcm_host_init
  
  state = CubeState.new
  
  # Start OGLES
  init_ogl(state)

  # Setup the model world
  init_model_proj(state)

  # initialise the OGLES texture(s)
  init_textures(state)

  counter = 0
  while !$terminate do  
    sleep(0.005)
    counter += 1
    update_model(state)
    redraw_scene(state)
    if counter >= 1000
      puts "In render loop ..."
      counter = 0
    end
  end

  exit_func(state)
  return 0;
end

status = main
exit(status)

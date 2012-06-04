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

$:.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'raspigl/bcm_host'
require 'raspigl/egl'

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
end



$terminate = false

trap("INT") { $terminate = true }

def main
  RaspiGL::BCMHost.bcm_host_init
  
  state = CubeState.new
  
  # Start OGLES
  init_ogl(state)

  # Setup the model world
#  init_model_proj(state)

  # initialise the OGLES texture(s)
#  init_textures(state);

  counter = 0
  while !$terminate do  
    sleep(0.005)
    counter += 1
#    update_model(state);
#    redraw_scene(state);
    if counter >= 1000
      puts "In render loop ..."
      counter = 0
    end
  end

#  exit_func
  return 0;
end

status = main
exit(status)

#
# Original C header Copyright (c) 2012 Broadcom Europe Ltd
# Ruby FFI translation Copyright (c) 2012 Phil Stewart
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
# bcm_host.h header file translated to Ruby FFI

require 'ffi'
require File.join(File.dirname(__FILE__), 'common')
module RaspiGL::BCMHost
  extend FFI::Library
  ffi_lib File.join(RaspiGL::VC_PATH, 'lib', 'libbcm_host.so')
  
  attach_function :bcm_host_init,   [], :void
  attach_function :bcm_host_deinit, [], :void
  
  class VC_RECT_T < FFI::Struct
    layout :x,      :int,
           :y,      :int,
           :width,  :int,
           :height, :int
  end

  DISPMANX_PROTECTION_MAX  = 0x0f
  DISPMANX_PROTECTION_NONE = 0
  DISPMANX_PROTECTION_HDCP = 11

  DISPMANX_NO_HANDLE       = 0

  DISPMANX_ID_MAIN_LCD     = 0
  DISPMANX_ID_AUX_LCD      = 1
  DISPMANX_ID_HDMI         = 2
  DISPMANX_ID_SDTV         = 3

  DISPMANX_STATUS_T = enum(
    :DISPMANX_SUCCESS, 0,
    :DISPMANX_INVALID, -1
  )
  
  DISPMANX_TRANSFORM_T = enum(
    :DISPMANX_NO_ROTATE,  0,
    :DISPMANX_ROTATE_90,  1,
    :DISPMANX_ROTATE_180, 2,
    :DISPMANX_ROTATE_270, 3,
    :DISPMANX_FLIP_HRIZ,  1 << 16,
    :DISPMANX_FLIP_VERT,  1 << 17
  )
  
  DISPMANX_FLAGS_ALPHA_T = enum(
    :DISPMANX_FLAGS_ALPHA_FROM_SOURCE,       0,
    :DISPMANX_FLAGS_ALPHA_FIXED_ALL_PIXELS,  1,
    :DISPMANX_FLAGS_ALPHA_FIXED_NON_ZERO,    2,
    :DISPMANX_FLAGS_ALPHA_FIXED_EXCEED_0X07, 3,
    :DISPMANX_FLAGS_ALPHA_PREMULT,           1 << 16,
    :DISPMANX_FLAGS_ALPHA_MIX,               1 << 17
  )

  class DISPMANX_ALPHA_T < FFI::Struct
    layout :flags,   DISPMANX_FLAGS_ALPHA_T,
           :opacity, :uint,
           :mask,    :pointer
  end

  class VC_DISPMANX_ALPHA_T < FFI::Struct
    layout :flags,   DISPMANX_FLAGS_ALPHA_T,
           :opacity, :uint,
           :mask,    :uint
  end

  DISPMANX_FLAGS_CLAMP_T = enum(
    :DISPMANX_FLAGS_CLAMP_NONE,             0,
    :DISPMANX_FLAGS_CLAMP_LUMA_TRANSPARENT, 1,
    :DISPMANX_FLAGS_CLAMP_TRANSPARENT,      2,
    :DISPMANX_FLAGS_CLAMP_REPLACE,          3
  )
  
  DISPMANX_FLAGS_KEYMASK_T = enum(
    :DISPMANX_FLAGS_KEYMASK_OVERRIDE, 1,
    :DISPMANX_FLAGS_KEYMASK_SMOOTH,   1 << 1,
    :DISPMANX_FLAGS_KEYMASK_CR_INV,   1 << 2,
    :DISPMANX_FLAGS_KEYMASK_CB_INV,   1 << 3,
    :DISPMANX_FLAGS_KEYMASK_YY_INV,   1 << 4
  )
  
  class DISPMANX_CLAMP_KEYS_YUV_S < FFI::Struct
    layout :yy_upper, :uint8,
           :yy_lower, :uint8,
           :cr_upper, :uint8,
           :cr_lower, :uint8,
           :cb_upper, :uint8,
           :cb_lower, :uint8
  end

  class DISPMANX_CLAMP_KEYS_RGB_S < FFI::Struct 
    layout :red_upper,   :uint8,
           :red_lower,   :uint8,
           :blue_upper,  :uint8,
           :blue_lower,  :uint8,
           :green_upper, :uint8,
           :green_lower, :uint8
  end
  
  class DISPMANX_CLAMP_KEYS_T < FFI::Union
    layout :yuv, DISPMANX_CLAMP_KEYS_YUV_S,
           :rgb, DISPMANX_CLAMP_KEYS_RGB_S
  end
  
  class DISPMANX_CLAMP_T < FFI::Struct
    layout :mode,          DISPMANX_FLAGS_CLAMP_T,
           :key_mask,      DISPMANX_FLAGS_KEYMASK_T,
           :key_value,     DISPMANX_CLAMP_KEYS_T,
           :replace_value, :uint
  end

  TRANSFORM_HFLIP =     1 << 0
  TRANSFORM_VFLIP =     1 << 1
  TRANSFORM_TRANSPOSE = 1 << 2

  VC_IMAGE_TRANSFORM_T = enum(
    :VC_IMAGE_ROT0,           0,
    :VC_IMAGE_MIRROR_ROT0,    TRANSFORM_HFLIP,
    :VC_IMAGE_MIRROR_ROT180,  TRANSFORM_VFLIP,
    :VC_IMAGE_ROT180,         TRANSFORM_HFLIP | TRANSFORM_VFLIP,
    :VC_IMAGE_MIRROR_ROT90,   TRANSFORM_TRANSPOSE,
    :VC_IMAGE_ROT270,         TRANSFORM_TRANSPOSE | TRANSFORM_HFLIP,
    :VC_IMAGE_ROT90,          TRANSFORM_TRANSPOSE | TRANSFORM_VFLIP,
    :VC_IMAGE_MIRROR_ROT270,  TRANSFORM_TRANSPOSE | TRANSFORM_HFLIP | TRANSFORM_VFLIP
  )

  VCOS_DISPLAY_INPUT_FORMAT_T = enum(
    :VCOS_DISPLAY_INPUT_FORMAT_INVALID, 0,
    :VCOS_DISPLAY_INPUT_FORMAT_RGB888,
    :VCOS_DISPLAY_INPUT_FORMAT_RGB565
  )

  class Tag_DISPMANX_MODEINFO_T < FFI::Struct
    layout :width,        :int,
           :height,       :int,
           :transform,    VC_IMAGE_TRANSFORM_T,
           :input_format, VCOS_DISPLAY_INPUT_FORMAT_T
  end

  HDMI_MODE_T = enum(
    :HDMI_MODE_OFF,
    :HDMI_MODE_DVI,
    :HDMI_MODE_HDMI,
    :HDMI_MODE_3D
  )

  HDMI_RES_GROUP_T = enum(
    :HDMI_RES_GROUP_INVALID, 0,
    :HDMI_RES_GROUP_CEA,     1,
    :HDMI_RES_GROUP_DMT,     2,
    :HDMI_RES_GROUP_CEA_3D,  3
  )

  EDID_MODE_MATCH_FLAG_T = enum(
    :HDMI_MODE_MATCH_NONE,       0x0,
    :HDMI_MODE_MATCH_FRAMERATE,  0x1,
    :HDMI_MODE_MATCH_RESOLUTION, 0x2,
    :HDMI_MODE_MATCH_SCANMODE,   0x4
  )

  HDMI_INTERLACED_T = enum(
    :HDMI_NONINTERLACED,
    :HDMI_INTERLACED
  )
  
  attach_function :vc_dispmanx_display_open,       [:uint], :uint
  attach_function :vc_dispmanx_update_start,       [:uint], :uint
  attach_function :vc_dispmanx_element_add,        [:uint, :uint, :int, :pointer, :int, :pointer,
                                                    :int, :pointer, :pointer, DISPMANX_TRANSFORM_T], :uint
  attach_function :vc_dispmanx_update_submit_sync, [:uint], :int
  attach_function :vc_dispmanx_element_remove,     [:uint, :uint], :int
  attach_function :vc_dispmanx_display_close,      [:uint], :int

  attach_function :graphics_get_display_size,      [:ushort, :pointer, :pointer], :int
  
  attach_function :vc_dispmanx_display_get_info,   [:uint, :pointer], :int

  attach_function :vc_dispmanx_display_set_background, [:uint, :uint, :uint8, :uint8, :uint8], :int
end

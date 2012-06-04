#
# Original C header Copyright (c) 2007-2009 The Khronos Group Inc.
# Ruby FFI translation Copyright (c) 2012 Phil Stewart
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and/or associated documentation files (the
# "Materials"), to deal in the Materials without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Materials, and to
# permit persons to whom the Materials are furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Materials.
#
# THE MATERIALS ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# MATERIALS OR THE USE OR OTHER DEALINGS IN THE MATERIALS.
#


require 'ffi'
require File.join(File.dirname(__FILE__), 'common')

module RaspiGL::EGL
  extend FFI::Library
  ffi_lib File.join(RaspiGL::VC_PATH, 'lib', 'libEGL.so')

  class EGL_DISPMANX_WINDOW_T < FFI::Struct
    layout :element, :int32,
           :width,   :int,
           :height,  :int
  end

  # EGL Versioning
  EGL_VERSION_1_0               = 1
  EGL_VERSION_1_1               = 1
  EGL_VERSION_1_2               = 1
  EGL_VERSION_1_3               = 1
  EGL_VERSION_1_4               = 1

  # EGL Enumerants. Bitmasks and other exceptional cases aside, most
  # enums are assigned unique values starting at 0x3000.
  #
  
  # EGL aliases
  EGL_FALSE                     = 0
  EGL_TRUE                      = 1
  
  # Out-of-band handle values
  EGL_DEFAULT_DISPLAY           = FFI::Pointer.new(:void, 0)
  EGL_NO_CONTEXT                = FFI::Pointer.new(:void, 0)
  EGL_NO_DISPLAY                = FFI::Pointer.new(:void, 0)
  EGL_NO_SURFACE                = FFI::Pointer.new(:void, 0)
  
  # Out-of-band attribute value
  EGL_DONT_CARE                 = -1

  # Errors / GetError return values
  EGL_SUCCESS                   = 0x3000
  EGL_NOT_INITIALIZED           = 0x3001
  EGL_BAD_ACCESS                = 0x3002
  EGL_BAD_ALLOC                 = 0x3003
  EGL_BAD_ATTRIBUTE             = 0x3004
  EGL_BAD_CONFIG                = 0x3005
  EGL_BAD_CONTEXT               = 0x3006
  EGL_BAD_CURRENT_SURFACE       = 0x3007
  EGL_BAD_DISPLAY               = 0x3008
  EGL_BAD_MATCH                 = 0x3009
  EGL_BAD_NATIVE_PIXMAP         = 0x300A
  EGL_BAD_NATIVE_WINDOW         = 0x300B
  EGL_BAD_PARAMETER             = 0x300C
  EGL_BAD_SURFACE               = 0x300D
  EGL_CONTEXT_LOST              = 0x300E  # EGL 1.1 - IMG_power_management

  # Reserved 0x300F-0x301F for additional errors

  # Config attributes
  EGL_BUFFER_SIZE               = 0x3020
  EGL_ALPHA_SIZE                = 0x3021
  EGL_BLUE_SIZE                 = 0x3022
  EGL_GREEN_SIZE                = 0x3023
  EGL_RED_SIZE                  = 0x3024
  EGL_DEPTH_SIZE                = 0x3025
  EGL_STENCIL_SIZE              = 0x3026
  EGL_CONFIG_CAVEAT             = 0x3027
  EGL_CONFIG_ID                 = 0x3028
  EGL_LEVEL                     = 0x3029
  EGL_MAX_PBUFFER_HEIGHT        = 0x302A
  EGL_MAX_PBUFFER_PIXELS        = 0x302B
  EGL_MAX_PBUFFER_WIDTH         = 0x302C
  EGL_NATIVE_RENDERABLE         = 0x302D
  EGL_NATIVE_VISUAL_ID          = 0x302E
  EGL_NATIVE_VISUAL_TYPE        = 0x302F
  EGL_SAMPLES                   = 0x3031
  EGL_SAMPLE_BUFFERS            = 0x3032
  EGL_SURFACE_TYPE              = 0x3033
  EGL_TRANSPARENT_TYPE          = 0x3034
  EGL_TRANSPARENT_BLUE_VALUE    = 0x3035
  EGL_TRANSPARENT_GREEN_VALUE   = 0x3036
  EGL_TRANSPARENT_RED_VALUE     = 0x3037
  EGL_NONE                      = 0x3038  # Attrib list terminator
  EGL_BIND_TO_TEXTURE_RGB       = 0x3039
  EGL_BIND_TO_TEXTURE_RGBA      = 0x303A
  EGL_MIN_SWAP_INTERVAL         = 0x303B
  EGL_MAX_SWAP_INTERVAL         = 0x303C
  EGL_LUMINANCE_SIZE            = 0x303D
  EGL_ALPHA_MASK_SIZE           = 0x303E
  EGL_COLOR_BUFFER_TYPE         = 0x303F
  EGL_RENDERABLE_TYPE           = 0x3040
  EGL_MATCH_NATIVE_PIXMAP       = 0x3041  # Pseudo-attribute (not queryable)
  EGL_CONFORMANT                = 0x3042

  # Reserved 0x3041-0x304F for additional config attributes

  # Config attribute values
  EGL_SLOW_CONFIG               = 0x3050  # EGL_CONFIG_CAVEAT value
  EGL_NON_CONFORMANT_CONFIG     = 0x3051  # EGL_CONFIG_CAVEAT value
  EGL_TRANSPARENT_RGB           = 0x3052  # EGL_TRANSPARENT_TYPE value
  EGL_RGB_BUFFER                = 0x308E  # EGL_COLOR_BUFFER_TYPE value
  EGL_LUMINANCE_BUFFER          = 0x308F  # EGL_COLOR_BUFFER_TYPE value

  # More config attribute values, for EGL_TEXTURE_FORMAT
  EGL_NO_TEXTURE                = 0x305C
  EGL_TEXTURE_RGB               = 0x305D
  EGL_TEXTURE_RGBA              = 0x305E
  EGL_TEXTURE_2D                = 0x305F

  # Config attribute mask bits
  EGL_PBUFFER_BIT               = 0x0001  # EGL_SURFACE_TYPE mask bits
  EGL_PIXMAP_BIT                = 0x0002  # EGL_SURFACE_TYPE mask bits
  EGL_WINDOW_BIT                = 0x0004  # EGL_SURFACE_TYPE mask bits
  EGL_VG_COLORSPACE_LINEAR_BIT  = 0x0020  # EGL_SURFACE_TYPE mask bits
  EGL_VG_ALPHA_FORMAT_PRE_BIT   = 0x0040  # EGL_SURFACE_TYPE mask bits
  EGL_MULTISAMPLE_RESOLVE_BOX_BIT = 0x0200  # EGL_SURFACE_TYPE mask bits
  EGL_SWAP_BEHAVIOR_PRESERVED_BIT = 0x0400  # EGL_SURFACE_TYPE mask bits

  EGL_OPENGL_ES_BIT             = 0x0001  # EGL_RENDERABLE_TYPE mask bits
  EGL_OPENVG_BIT                = 0x0002  # EGL_RENDERABLE_TYPE mask bits
  EGL_OPENGL_ES2_BIT            = 0x0004  # EGL_RENDERABLE_TYPE mask bits
  EGL_OPENGL_BIT                = 0x0008  # EGL_RENDERABLE_TYPE mask bits

  # QueryString targets
  EGL_VENDOR                    = 0x3053
  EGL_VERSION                   = 0x3054
  EGL_EXTENSIONS                = 0x3055
  EGL_CLIENT_APIS               = 0x308D
  
  # QuerySurface / SurfaceAttrib / CreatePbufferSurface targets
  EGL_HEIGHT                    = 0x3056
  EGL_WIDTH                     = 0x3057
  EGL_LARGEST_PBUFFER           = 0x3058
  EGL_TEXTURE_FORMAT            = 0x3080
  EGL_TEXTURE_TARGET            = 0x3081
  EGL_MIPMAP_TEXTURE            = 0x3082
  EGL_MIPMAP_LEVEL              = 0x3083
  EGL_RENDER_BUFFER             = 0x3086
  EGL_VG_COLORSPACE             = 0x3087
  EGL_VG_ALPHA_FORMAT           = 0x3088
  EGL_HORIZONTAL_RESOLUTION     = 0x3090
  EGL_VERTICAL_RESOLUTION       = 0x3091
  EGL_PIXEL_ASPECT_RATIO        = 0x3092
  EGL_SWAP_BEHAVIOR             = 0x3093
  EGL_MULTISAMPLE_RESOLVE       = 0x3099

  # EGL_RENDER_BUFFER values / BindTexImage / ReleaseTexImage buffer targets
  EGL_BACK_BUFFER               = 0x3084
  EGL_SINGLE_BUFFER             = 0x3085

  # OpenVG color spaces
  EGL_VG_COLORSPACE_sRGB        = 0x3089  # EGL_VG_COLORSPACE value
  EGL_VG_COLORSPACE_LINEAR      = 0x308A  # EGL_VG_COLORSPACE value

  # OpenVG alpha formats
  EGL_VG_ALPHA_FORMAT_NONPRE    = 0x308B  # EGL_ALPHA_FORMAT value
  EGL_VG_ALPHA_FORMAT_PRE       = 0x308C  # EGL_ALPHA_FORMAT value

  # Constant scale factor by which fractional display resolutions &
  # aspect ratio are scaled when queried as integer values.

  EGL_DISPLAY_SCALING           = 10000
  
  # Unknown display resolution/aspect ratio
  EGL_UNKNOWN                   = -1
  
  # Back buffer swap behaviors
  EGL_BUFFER_PRESERVED          = 0x3094  # EGL_SWAP_BEHAVIOR value
  EGL_BUFFER_DESTROYED          = 0x3095  # EGL_SWAP_BEHAVIOR value
  
  # CreatePbufferFromClientBuffer buffer types
  EGL_OPENVG_IMAGE              = 0x3096
  
  # QueryContext targets
  EGL_CONTEXT_CLIENT_TYPE       = 0x3097

  # CreateContext attributes
  EGL_CONTEXT_CLIENT_VERSION    = 0x3098

  # Multisample resolution behaviors
  EGL_MULTISAMPLE_RESOLVE_DEFAULT = 0x309A  # EGL_MULTISAMPLE_RESOLVE value
  EGL_MULTISAMPLE_RESOLVE_BOX   = 0x309B  # EGL_MULTISAMPLE_RESOLVE value

  # BindAPI/QueryAPI targets
  EGL_OPENGL_ES_API             = 0x30A0
  EGL_OPENVG_API                = 0x30A1
  EGL_OPENGL_API                = 0x30A2

  # GetCurrentSurface targets
  EGL_DRAW                      = 0x3059
  EGL_READ                      = 0x305A

  # WaitNative engines
  EGL_CORE_NATIVE_ENGINE        = 0x305B

  attach_function :eglGetError,        [], :int
  
  attach_function :eglGetDisplay,      [:pointer], :pointer
  attach_function :eglInitialize,      [:pointer, :pointer, :pointer], :uint
  attach_function :eglTerminate,       [:pointer], :uint

  attach_function :eglQueryString,     [:pointer, :int], :string

  attach_function :eglGetConfigs,      [:pointer, :pointer, :int, :pointer], :uint
  attach_function :eglChooseConfig,    [:pointer, :pointer, :pointer, :int, :pointer], :uint
  attach_function :eglGetConfigAttrib, [:pointer, :pointer, :int, :pointer], :uint

  attach_function :eglCreateWindowSurface,  [:pointer, :pointer, :pointer, :pointer], :pointer
  attach_function :eglCreatePbufferSurface, [:pointer, :pointer, :pointer], :pointer
  attach_function :eglCreatePixmapSurface,  [:pointer, :pointer, :pointer, :pointer], :pointer
  attach_function :eglDestroySurface,       [:pointer, :pointer], :uint
  attach_function :eglQuerySurface,         [:pointer, :pointer, :int, :pointer], :uint

  attach_function :eglBindAPI,         [:uint], :uint
  attach_function :eglQueryAPI,        [], :uint

  attach_function :eglWaitClient,      [], :uint

  attach_function :eglReleaseThread,   [], :uint

  attach_function :eglCreatePbufferFromClientBuffer, [:pointer, :uint, :pointer, :pointer, :pointer], :pointer

  attach_function :eglSurfaceAttrib,   [:pointer, :pointer, :int, :int], :uint
  attach_function :eglBindTexImage,    [:pointer, :pointer, :int], :uint
  attach_function :eglReleaseTexImage, [:pointer, :pointer, :int], :uint


  attach_function :eglSwapInterval,    [:pointer, :int], :uint


  attach_function :eglCreateContext,   [:pointer, :pointer, :pointer, :pointer], :pointer
  attach_function :eglDestroyContext,  [:pointer, :pointer], :uint
  attach_function :eglMakeCurrent,     [:pointer, :pointer, :pointer, :pointer], :uint

  attach_function :eglGetCurrentContext,    [], :pointer
  attach_function :eglGetCurrentSurface,    [:int], :pointer
  attach_function :eglGetCurrentDisplay,    [], :pointer
  attach_function :eglQueryContext,         [:pointer, :pointer, :int, :pointer], :uint

  attach_function :eglWaitGL,          [], :uint
  attach_function :eglWaitNative,      [:int], :uint
  attach_function :eglSwapBuffers,     [:pointer, :pointer], :uint
  attach_function :eglCopyBuffers,     [:pointer, :pointer, :pointer], :uint

end

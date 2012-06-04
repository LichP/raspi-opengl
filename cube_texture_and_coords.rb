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

require 'ffi'

# Spatial coordinates for the cube
$quadx = FFI::MemoryPointer.new(:int8, 6 * 4 * 3)
$quadx.write_array_of_int8([
   # FRONT
   -10, -10,  10,
   10, -10,  10,
   -10,  10,  10,
   10,  10,  10,

   # BACK
   -10, -10, -10,
   -10,  10, -10,
   10, -10, -10,
   10,  10, -10,

   # LEFT
   -10, -10,  10,
   -10,  10,  10,
   -10, -10, -10,
   -10,  10, -10,

   # RIGHT
   10, -10, -10,
   10,  10, -10,
   10, -10,  10,
   10,  10,  10,

   # TOP
   -10,  10,  10,
   10,  10,  10,
   -10,  10, -10,
   10,  10, -10,

   # BOTTOM
   -10, -10,  10,
   -10, -10, -10,
   10, -10,  10,
   10, -10, -10,
])

# Texture coordinates for the quad.
$texCoords = FFI::MemoryPointer.new(:float, 6 * 4 * 2)
$texCoords.write_array_of_float([
   0.0,  0.0,
   0.0,  1.0,
   1.0,  0.0,
   1.0,  1.0,

   0.0,  0.0,
   0.0,  1.0,
   1.0,  0.0,
   1.0,  1.0,

   0.0,  0.0,
   0.0,  1.0,
   1.0,  0.0,
   1.0,  1.0,

   0.0,  0.0,
   0.0,  1.0,
   1.0,  0.0,
   1.0,  1.0,

   0.0,  0.0,
   0.0,  1.0,
   1.0,  0.0,
   1.0,  1.0,

   0.0,  0.0,
   0.0,  1.0,
   1.0,  0.0,
   1.0,  1.0
])

$colorsf = FFI::MemoryPointer.new(:float, 6 * 4 * 4)
$colorsf.write_array_of_float([
   1.0,  0.0,  0.0,  1.0, # red
   1.0,  0.0,  0.0,  1.0,
   1.0,  0.0,  0.0,  1.0,
   1.0,  0.0,  0.0,  1.0,

   0.0,  1.0,  0.0,  1.0, # blue
   0.0,  1.0,  0.0,  1.0,
   0.0,  1.0,  0.0,  1.0,
   0.0,  1.0,  0.0,  1.0,

   0.0,  0.0,  1.0,  1.0, # green
   0.0,  0.0,  1.0,  1.0,
   0.0,  0.0,  1.0,  1.0,
   0.0,  0.0,  1.0,  1.0,

   0.0, 0.5, 0.5,  1.0,   # teal
   0.0, 0.5, 0.5,  1.0,
   0.0, 0.5, 0.5,  1.0,
   0.0, 0.5, 0.5,  1.0,

   0.5, 0.5,  0.0,  1.0,  # yellow
   0.5, 0.5,  0.0,  1.0,
   0.5, 0.5,  0.0,  1.0,
   0.5, 0.5,  0.0,  1.0,

   0.5,  0.0, 0.5,  1.0,  # purple
   0.5,  0.0, 0.5,  1.0,
   0.5,  0.0, 0.5,  1.0,
   0.5,  0.0, 0.5,  1.0
])


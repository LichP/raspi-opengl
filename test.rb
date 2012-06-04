#!/usr/bin/ruby1.9.1
$:.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'raspigl/bcm_host'
require 'raspigl/egl'
require 'pry'

binding.pry

require 'rubygems'
require 'test/unit'
require 'fakefs/safe'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'scratchpad'

class Test::Unit::TestCase
end

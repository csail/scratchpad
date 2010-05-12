require 'helper.rb'

class ManufacturerTest < Test::Unit::TestCase
  Manufacturer = Scratchpad::Models::Manufacturer
  
  def setup
    @manufacturer = Manufacturer.new
  end
  
  def test_attributes
    attributes = @manufacturer.attributes
    
    assert attributes[:key], 'Missing CA key.'
    assert attributes[:cert], 'Missing CA certificate.'
  end
  
  def test_serializing
    attributes = @manufacturer.attributes
    manufacturer2 = Manufacturer.new attributes
    attributes2 = manufacturer2.attributes
    
    assert_equal attributes[:key], attributes2[:key], 'CA key not preserved'
    assert_equal attributes[:cert], attributes2[:cert], 'CA cert not preserved'
  end
  
  def test_dev_instance
    dm = Manufacturer.dev_instance
    dm2 = Manufacturer.dev_instance
    
    assert_equal dm.attributes, dm2.attributes, 'Dev instance not constant'
  end
end

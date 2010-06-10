require File.expand_path('../helper.rb', __FILE__)

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
    crt_file = File.expand_path(
        '../../lib/scratchpad/dev_keys/manufacturer.crt', __FILE__)
    FakeFS do
      Dir.glob('dev_keys/*').each { |f| File.delete f }
      dm = Manufacturer.dev_instance
      dm2 = Manufacturer.dev_instance
    
      assert_equal dm.attributes, dm2.attributes, 'Dev instance not constant'
      assert File.exist?(crt_file), 'Missing dev manufacturer CA certificate'
    end
  end
  
  def test_valid_device_cert
    pair = @manufacturer.device_pair
    fpga = pair[:fpga]
    
    manufacturer2 = Manufacturer.new
    pair2 = manufacturer2.device_pair
    fpga2 = pair2[:fpga]
    
    assert @manufacturer.valid_device_cert?(fpga.endorsement_certificate),
           'Manufacturer 1 does not recognize its own device'
    assert manufacturer2.valid_device_cert?(fpga2.endorsement_certificate),
        'Manufacturer 2 does not recognize its own device'
    assert !@manufacturer.valid_device_cert?(fpga2.endorsement_certificate),
           'Manufacturer 1 validated manufacturer 2 device'
    assert !manufacturer2.valid_device_cert?(fpga.endorsement_certificate),
           'Manufacturer 2 validated manufacturer 1 device'
  end
end

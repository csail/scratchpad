require File.expand_path('../helper.rb', __FILE__)

class DiskTest < Test::Unit::TestCase
  Disk = Scratchpad::Models::Disk
  
  def setup
    @disk = Disk.new 64 * 1024, :block_count => 64    
  end
  
  def test_block_size
    assert_equal 64 * 1024, @disk.block_size
  end
  
  def test_block_count
    assert_equal 64, @disk.block_count
  end
  
  def test_empty_reads    
    blank = "\0" * @disk.block_size
    0.upto(@disk.block_count - 1) do |i|
      assert_equal blank, @disk.read_blocks(i, 1),
                   "Incorrect contents for empty block"
    end
  end
  
  def test_one_block
    block = "01234567" * (@disk.block_size / 8)
    @disk.write_blocks 29, 1, block
    assert_equal block, @disk.read_blocks(29, 1), "Incorrect block contents"
  end
  
  def test_block_set
    block = "0123456" * @disk.block_size
    @disk.write_blocks 29, 7, block
    assert_equal block, @disk.read_blocks(29, 7), "Incorrect block contents"    
  end
end

require 'photobook'
require 'minitest/autorun'
require_relative 'helper'

class TestArranger < Minitest::Unit::TestCase

  include TestHelper

  def make_layout_manager
    return Photobook::LayoutManager.new({
      'layout-v' => { 'pattern' => 'v' },
      'layout-h' => { 'pattern' => 'h' },
      'layout-aa' => { 'pattern' => 'aa' },
    })
  end

  def make_photos(num_h, num_v, random = true)
    res = (1..num_h).map { |x| Photobook::Photo.new("photo-h-#{x}", :h) }
    res += (1..num_v).map { |x| Photobook::Photo.new("photo-v-#{x}", :v) }
    res = res.sample(res.count) if rand
    return res
  end

  def test_arrange
    lm = make_layout_manager
    photos = make_photos(100, 100)
    exp_photos = photos.dup
    arr = Photobook::Arranger.new(lm, photos)
    res = arr.arrange

    assert_instance_of Array, res
    assert_equal exp_photos, photos

    res.each do |obj|
      obj.must_be_instance_of(Photobook::Group)
      assert_equal lm.layout_for(obj.layout.name), obj.layout
      assert_operator obj.photos.count, :<=, exp_photos.count
      these_exp_photos = exp_photos.shift(obj.photos.count)
      assert_empty obj.photos - these_exp_photos
      assert_empty these_exp_photos - obj.photos
    end
    assert_empty exp_photos
  end

end

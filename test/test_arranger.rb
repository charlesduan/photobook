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
      'layout-aaaaa' => { 'pattern' => 'aaaaa' },
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

  def make_group(layout)
    i = 0
    return Photobook::Group.new(layout, layout.pattern.map { |p|
      i += 1
      p = :v if p == :a
      Photobook::Photo.new("photo-#{i}", p)
    })
  end

  def test_score_arrangement
    lm = make_layout_manager
    arr = Photobook::Arranger.new(lm, [])
    group1 = make_group(lm.layout_for('layout-v'))
    group2 = make_group(lm.layout_for('layout-h'))
    group3 = make_group(lm.layout_for('layout-aa'))
    group4 = make_group(lm.layout_for('layout-aaaaa'))
    assert_equal 1, arr.score_arrangement([ [], group1 ])
    assert_equal 5, arr.score_arrangement([ [], group4 ])
    assert_equal 4, arr.score_arrangement([ [ group1 ], group4 ])
    assert_equal 4, arr.score_arrangement([ [ group4 ], group1 ])
    try_cases(
      [ [ [ group1 ], group4 ], :==, [ [ group4 ], group1 ] ],
      [ [ [ group1 ], group1 ], :<, [ [ group2 ], group1 ] ],
      [ [ [ group2 ], group1 ], :<, [ [ group3 ], group1 ] ],
      [ [ [ group2 ], group1 ], :<, [ [ group1 ], group3 ] ],
      [ [ [ group1, group2 ], group3 ], :==, [ [ group4, group2 ], group3 ] ],
      [ [ [ group1, group2 ], group3 ], :>, [ [ group3, group2 ], group3 ] ],
    ) do |arr1, op, arr2|
      arr.score_arrangement(arr1).must_be(op, arr.score_arrangement(arr2))
    end
  end

end

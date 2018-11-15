require 'photobook'
require 'minitest/autorun'
require_relative 'helper'

class TestLayout < Minitest::Unit::TestCase

  include TestHelper

  def test_new
    try_cases(
      [ 1, 'h', 1, [ :h ] ],
      [ 2, 'hlvpa*', 6, [ :h, :h, :v, :v, :a, :a ] ],
      [ 1, 'hhhh', 4, [ :h, :h, :h, :h ] ]
    ) do |pages, pat, exp_used, exp_pat|
      pp = Photobook::Layout.new(
        'test layout',
        'pages' => pages,
        'pattern' => pat,
      )
      assert_equal('test layout', pp.name)
      assert_equal(pages, pp.pages_used)
      assert_equal(exp_used, pp.photos_used)
      assert_equal(exp_pat, pp.pattern)
    end
  end

  def make_photos(orient)
    count = 0
    return orient.split('').map { |x|
      count += 1
      Photobook::Photo.new("Photo #{count}", x.to_sym)
    }
  end

  def test_match_fail
    try_cases(
      [ 'v', '' ],
      [ 'v', 'h' ],
      [ 'v', 'vv' ],
      [ 'a', '' ],
      [ 'a', 'hv' ],
    ) do |pat, orient|
      photos = make_photos(orient)
      pp = Photobook::Layout.new('test layout', 'pattern' => pat)
      assert_nil(pp.match(photos), 'Match not expected')
    end
  end

  def test_match_success
    try_cases(
      [ 'h', 'h', '1' ],
      [ 'v', 'v', '1' ],
      [ 'a', 'h', '1' ],
      [ 'a', 'v', '1' ],
      [ 'aa', 'hv', '12' ],
      [ 'ah', 'hh', '12' ],
      [ 'ah', 'hv', '21' ],
      [ 'ah', 'vh', '12' ],
      [ 'aaav', 'vvhh', '1342' ],
      [ 'aaavh', 'vvvhh', '12435' ],
      [ 'aaavh', 'vvhhh', '13425' ],
      [ 'vhaaa', 'hhhvv', '41235' ],
      [ 'vvvhhh', 'hhhvvv', '456123' ]
    ) do |pat, orient, exp|
      photos = make_photos(orient)
      pp = Photobook::Layout.new('test layout', 'pattern' => pat)
      res = pp.match(photos)
      refute_nil(res, "Match expected but not found")
      assert_instance_of(Array, res)
      assert_equal(exp.length, res.count)
      res.zip(exp.split('')).each do |res_photo, exp_photo|
        assert_instance_of(Photobook::Photo, res_photo)
        assert_equal("Photo #{exp_photo}", res_photo.name)
      end
    end
  end

end

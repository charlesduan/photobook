require 'photobook'
require 'minitest/autorun'
require_relative 'helper'

class TestPhotoList < Minitest::Unit::TestCase

  include TestHelper

  def test_group
    layout = Photobook::Layout.new('layout', 'pattern' => 'v')
    photo = Photobook::Photo.new('photo', :v)
    params = { 'background' => 'black' }
    group = Photobook::Group.new(layout, [ photo ], params)
    assert_equal params, group.params
    assert_equal layout, group.layout
    assert_equal [ photo ], group.photos

    exp_str = <<-EOF
PAGE layout
  background: black

photo (v)
-----
    EOF
    assert_equal exp_str, group.to_s
  end

  def test_group_no_layout
    photo = Photobook::Photo.new('photo', :v)
    params = { 'background' => 'black' }
    group = Photobook::Group.new(nil, [ photo ], params)
    assert_nil group.layout

    exp_str = <<-EOF
PAGE
  background: black

photo (v)
-----
    EOF
    assert_equal exp_str, group.to_s
  end

  def test_group_photos_only
    photo = Photobook::Photo.new('photo', :v)
    group = Photobook::Group.new(nil, [ photo ], {})
    assert_nil group.layout
    assert_equal({}, group.params)
    exp_str = "PAGE\nphoto (v)\n-----\n"
    assert_equal exp_str, group.to_s
  end

  def make_layout_manager
    return Photobook::LayoutManager.new({
      'layout-v' => { 'pattern' => 'v' },
      'layout-h' => { 'pattern' => 'h' },
      'layout-aa' => { 'pattern' => 'aa' },
    })
  end

  def test_new
    parts = {
      'b' => "\n",
      'B' => "   \n",
      's' => "-----\n",
      'p' => "PAGE\n",
      'v' => "PAGE layout-v\n",
      'h' => "PAGE layout-h\n",
      'a' => "PAGE layout-aa\n",
      'k' => "  background: black\n",
      'q' => "photo-q (v)\n",
      'w' => "photo-w (h)\n"
    }
    lm = make_layout_manager
    try_cases(
      [ 'qqqq', [ [ nil, false, 'vvvv' ] ] ],
      [ 'bqBqBqbqb', [ [ nil, false, 'vvvv' ] ] ],
      [ 'pBqqqqbsb', [ [ nil, false, 'vvvv' ] ] ],
      [ 'qsq', [ [ nil, false, 'v' ], [ nil, false, 'v' ] ] ],
      [ 'qspq', [ [ nil, false, 'v' ], [ nil, false, 'v' ] ] ],
      [ 'qspkq', [ [ nil, false, 'v' ], [ nil, true, 'v' ] ] ],
      [ 'akbqwsvq', [ [ 'aa', true, 'vh' ], [ 'v', false, 'v' ] ] ],
      [ 'wwwwsvq', [ [ nil, false, 'hhhh' ], [ 'v', false, 'v' ] ] ],
    ) do |lines, exps|
      text = lines.split("").map { |x| parts[x] }.join
      pl = Photobook::PhotoList.new(lm, text)
      assert_equal exps.count, pl.groups.count
      exps.zip(pl.groups).each do |exp, group|
        assert_instance_of Photobook::Group, group
        if exp[0].nil?
          assert_nil group.layout
        else
          assert_equal "layout-#{exp[0]}", group.layout.name
        end
        if exp[1]
          assert_equal({ 'background' => 'black' }, group.params)
        else
          assert_equal({}, group.params)
        end
        assert_equal exp[2], group.photos.map(&:orientation).join
      end
    end
  end

  def test_new_block
    called = []
    pl = Photobook::PhotoList.new(
      make_layout_manager,
      "photo1\nphoto2 (v)\nphoto3\n"
    ) do |photo|
      called.push(photo)
      return :v
    end
    assert_equal 1, pl.groups.count
    assert_equal 3, pl.groups.first.photos.count
    assert_equal [ :v, :v, :v ], pl.groups.first.photos.map(&:orientation)
    assert_equal [ 'photo1', 'photo3' ], called
  end

end

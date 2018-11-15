require 'photobook'
require 'minitest/autorun'
require_relative 'helper'

class TestLayoutManager < Minitest::Unit::TestCase

  include TestHelper

  def test_new
    lm = Photobook::LayoutManager.new({
      'layout 1' => { 'pattern' => 'vvv' },
      'layout 2' => { 'pattern' => 'h' }
    })
    assert_instance_of Hash, lm.layouts
    assert_equal 2, lm.layouts.count

    layout_1 = lm.layouts['layout 1']
    assert_instance_of Photobook::Layout, layout_1
    assert_equal 'layout 1', layout_1.name
    assert_equal [ :v, :v, :v ], layout_1.pattern

    layout_2 = lm.layouts['layout 2']
    assert_instance_of Photobook::Layout, layout_2
    assert_equal 'layout 2', layout_2.name
    assert_equal [ :h ], layout_2.pattern
  end

  def test_new_yaml
    data = <<-EOF
layout 1:
    pattern: vvv
layout 2:
    pattern: h
    EOF
    lm = Photobook::LayoutManager.new(data)

    assert_equal 2, lm.layouts.count

    layout_1 = lm.layouts['layout 1']
    assert_instance_of Photobook::Layout, layout_1
    assert_equal 'layout 1', layout_1.name
    assert_equal [ :v, :v, :v ], layout_1.pattern

    layout_2 = lm.layouts['layout 2']
    assert_instance_of Photobook::Layout, layout_2
    assert_equal 'layout 2', layout_2.name
    assert_equal [ :h ], layout_2.pattern
  end

  def test_layout_for
    lm = Photobook::LayoutManager.new({
      'layout 1' => { 'pattern' => 'vvv' },
      'layout 2' => { 'pattern' => 'h' }
    })

    layout_1 = lm.layout_for('layout 1')
    assert_instance_of Photobook::Layout, layout_1
    assert_equal 'layout 1', layout_1.name
    assert_equal [ :v, :v, :v ], layout_1.pattern

    layout_2 = lm.layout_for('layout 2')
    assert_instance_of Photobook::Layout, layout_2
    assert_equal 'layout 2', layout_2.name
    assert_equal [ :h ], layout_2.pattern

    assert_nil lm.layout_for('layout 3')
  end
end

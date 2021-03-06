require 'test_helper'
require 'foreman/renderer'

class RendererTest < ActiveSupport::TestCase
  include Foreman::Renderer

  def setup_normal_renderer
    Setting.stubs(:[]).with(:safemode_render).returns(false)
  end

  def setup_safemode_renderer
    Setting.stubs(:[]).with(:safemode_render).returns(true)
  end

  [:normal_renderer, :safemode_renderer].each do |renderer_name|
    test "#{renderer_name} is properly configured" do
      send "setup_#{renderer_name}"
      if renderer_name == :normal_renderer
        assert Setting[:safemode_render] == false
      else
        assert Setting[:safemode_render] == true
      end
    end

    test "#{renderer_name} should evaluate template variables" do
      send "setup_#{renderer_name}"
      tmpl = render_safe('<%= @foo %>', [], { :foo => 'bar' })
      assert_equal 'bar', tmpl
    end

    test "#{renderer_name} should evaluate renderer methods" do
      send "setup_#{renderer_name}"
      self.expects(:foreman_url).returns('bar')
      tmpl = render_safe('<%= foreman_url %>', [:foreman_url])
      assert_equal 'bar', tmpl
    end

    test "#{renderer_name} should render a snippet" do
      send "setup_#{renderer_name}"
      snippet = mock("snippet")
      snippet.expects(:name).returns("test")
      snippet.expects(:template).returns("content")
      ConfigTemplate.expects(:where).with(:name => "test", :snippet => true).returns([snippet])
      tmpl = snippet('test')
      assert_equal 'content', tmpl
    end

    test "#{renderer_name} should not raise error when snippet is not found" do
      send "setup_#{renderer_name}"
      ConfigTemplate.expects(:where).with(:name => "test", :snippet => true).returns([])
      assert_nil snippet_if_exists('test')
    end
  end

end

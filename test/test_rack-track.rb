require 'helper'

class TestRackTrack < Test::Unit::TestCase
  include Rack::Test::Methods
  
  def initialize(x)
    super(x)
    @rules = lambda {}
  end
  
  class SimpleApp
    def call(env)
      [200, {'Content-Type' => "text/html"}, ["<html><head><title></title></head><body>hello this is the body</body></html>"]]
    end
  end
  
  def app
    Rack::Track.new(SimpleApp.new, &@rules)
  end
  
  def test_defining_pixels_and_areas_with_dsl
    tp = Rack::Track::PixelSet.new do
      area :confirmation, "business-energy/confirmation", "business-communications/confirmation"
      
      pixel "Confirmation (GA)", :on => :confirmation do
        "THIS IS A GA CONFIRMATION TEST"
      end
    end

    assert tp.instance_variable_get(:@areas) == {:confirmation => ["business-energy/confirmation", "business-communications/confirmation"]}
    assert tp.instance_variable_get(:@pixels) == [Rack::Track::PixelSet::Pixel.new("Confirmation (GA)", :confirmation, "THIS IS A GA CONFIRMATION TEST")]
  end
  
  def test_psudo_area_all
    @rules = Proc.new do 
      pixel "Test pixel", :on => :all do
        "THIS-IS-A-TEST"
      end
    end
    get '/'
    assert last_response.body.include? "THIS-IS-A-TEST</body>"
    get '/poatoes'
    assert last_response.body.include? "THIS-IS-A-TEST</body>"
  end
  
  def test_area_inclusion
    @rules = Proc.new do 
      area :an_area, "/blah", "/blah/test"
      
      pixel "Test pixel", :on => :an_area do
        "THIS-IS-A-TEST"
      end
    end
    get '/'
    assert !last_response.body.include?("THIS-IS-A-TEST</body>")
    get '/blah'
    assert last_response.body.include? "THIS-IS-A-TEST</body>"
    get '/blah/test'
    assert last_response.body.include? "THIS-IS-A-TEST</body>"
  end
end

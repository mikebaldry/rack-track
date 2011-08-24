require 'helper'

class TestRackTrack < Test::Unit::TestCase
  include Rack::Test::Methods
  
  def initialize(x)
    super(x)
    @rules = lambda {}
    @app_class = SimpleApp
  end
  
  SAMPLE_RULE = Proc.new do 
    pixel "Test pixel", :on => :all do
      "THIS-IS-A-TEST"
    end
  end
  
  class SimpleApp
    def call(env)
      [200, {'Content-Type' => "text/html"}, ["<html><head><title></title></head><body>hello this is the body</body></html>"]]
    end
  end
  
  def app
    Rack::Track.new(@app_class.new, &@rules)
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
    @rules = SAMPLE_RULE
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
  
  def test_only_works_on_html_pages
    @app_class = Class.new do
      def call(env)
        [200, {'Content-Type' => "text/css"}, ["<html><head><title></title></head><body>hello this is the body</body></html>"]]
      end
    end
    
    @rules = SAMPLE_RULE
    
    get '/'
    assert last_response.body != "<html><head><title></title></head><body>hello this is the bodyTHIS-IS-A-TEST</body></html>"
  end
  
  def test_only_works_on_html_pages_with_charset
    @app_class = Class.new do
      def call(env)
        [200, {'Content-Type' => "text/html; charset=utf-8"}, ["<html><head><title></title></head><body>hello this is the body</body></html>"]]
      end
    end
    
    @rules = SAMPLE_RULE
    
    get '/'
    assert last_response.body == "<html><head><title></title></head><body>hello this is the bodyTHIS-IS-A-TEST</body></html>"
  end
  
  def test_only_works_on_pages_with_closing_body
    @app_class = Class.new do
      def call(env)
        [200, {'Content-Type' => "text/html; charset=utf-8"}, ["<html><head><title></title></head><body>hello this is the body</html>"]]
      end
    end
    
    @rules = SAMPLE_RULE
    
    get '/'
    assert last_response.body == "<html><head><title></title></head><body>hello this is the body</html>"
  end
  
  def test_fixes_content_length_header
    @app_class = Class.new do
      def call(env)
        [200, {'Content-Type' => "text/html; charset=utf-8"}, ["<html><head><title></title></head><body>hello this is the body</body></html>"]]
      end
    end
    
    @rules = SAMPLE_RULE
    
    get '/'
    assert_equal 90, last_response.headers["Content-Length"].to_i
  end
end
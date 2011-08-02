module Rack
  class Track
    def initialize(app, &block)
      @app = app
      @rules = Rack::Track::PixelSet.new &block
    end

    def call(env)
      request = Rack::Request.new(env)
      status, headers, response = @app.call(env)
      
      response_body = ""
      response.each { |p| response_body += p }
      
      [status, headers, [@rules.apply(request, response_body)]]
    end
  
    def each(&block)
    end
  
    private
  
    class PixelSet
      Pixel = Struct.new(:name, :area, :content)
    
      def initialize(&block)
        @pixels = []
        @areas = {}
        self.instance_eval(&block) if block_given?
      end
    
      def area(id, *paths)
        @areas[id] = [] unless @areas[id]
        paths.each { |path| @areas[id] << path.downcase }
      end
    
      def pixel(name, opts = {}, &block)
        @pixels << Pixel.new(name, opts[:on], block[])
      end
    
      def apply(request, response)
        url = URI::parse(request.url)
        @pixels.each do |p|
          paths = @areas[p.area]
          response.insert(response.rindex("</body>"), p.content) if p.area == :all || paths.include?(url.path.downcase)
        end
        response
      end
    end
  end
end
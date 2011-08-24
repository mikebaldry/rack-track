module Rack
  class Track
    def initialize(app, &block)
      @app = app
      @rules = Rack::Track::PixelSet.new &block
    end

    def call(env)
      request = Rack::Request.new(env)
      status, headers, response = @app.call(env)
      
      if /^text\/html/ =~ headers["Content-Type"]
        response_body = ""
        response.each { |p| response_body += p }
        response = [@rules.apply(request, response_body)] if response_body.include? "</body>"
        headers["Content-Length"] = response.inject(0){|sum,x| sum + x.length }.to_s
      end
      p headers
      [status, headers, response]
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
          response.insert(response.rindex("</body>"), p.content) if [:all_pages, :all].include?(p.area) || paths.include?(url.path.downcase)
        end
        response
      end
    end
  end
end
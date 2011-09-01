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
        headers["Content-Length"] = get_length(response)
      end
      [status, headers, response]
    end
  
    def each(&block)
    end
  
    private
  
    def get_length(response)
      sum_length = 0
      response.each {|x| sum_length += x.length }
      sum_length.to_s
    end
  
    class PixelSet
      Pixel = Struct.new(:name, :area, :except, :content)
    
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
        @pixels << Pixel.new(name, opts[:on], opts[:except] ? [opts[:except]].flatten : [], block[])
      end
    
      def apply(request, response)
        url = URI::parse(request.url)
        p "applying to #{url.path.downcase}"
        matching_areas = @areas.find_all { |k, a| a.include? url.path.downcase }.collect { |k, v| k }
        p matching_areas
        @pixels.each do |p|
          paths = @areas[p.area]
          response.insert(response.rindex("</body>"), p.content) if ([:all_pages, :all].include?(p.area) || 
                                                                    paths.include?(url.path.downcase)) &&
                                                                    p.except.find_all { |ea| matching_areas.include? ea }.empty?
        end
        response
      end
    end
  end
end
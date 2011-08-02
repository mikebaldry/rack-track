# Rack::Track

On too many projects I've worked on, nobody actually know every tracking pixel we have, what areas/pages they appear on (or should appear on) and it 
becomes a massive headache when you need to do work around them. This is where Rack::Track comes in to play, providing a DSL to define tracking pixels
and the areas they should appear on. It's all in one place, instead of across layouts and pages and it's self documenting. 

```ruby
MyApp::Application.config.middleware.use(Rack::Track) do
  area :confirmation_pages, "/checkout/order_confirmation", "/basket/complete"
  
  pixel "Generic GA", :on => :all_pages do
    %Q{
      <!-- GOOGLE ANALYTICS --> 
      blah
      <!-- END GOOGLE ANALYTICS --> 
    }
  end
  
  pixel "Goal GA", :on => :confirmation_pages do
    %Q{
      <!-- GOOGLE ANALYTICS --> 
      blah
      <!-- END GOOGLE ANALYTICS --> 
    }
  end
end
```
These tracking pixels will be inserted in to the page before the body tag closes. This is what most tracking pixels expect. If you require a pixel
to be placed in the head tag, or anywhere else, let me know and I'll extend it (or you could clone and submit a pull request with your changes!)

      $ gem install rack-track

      require "rack-track" # or "rack/track", whatever floats your boat.

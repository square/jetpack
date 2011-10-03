class ApplicationController < ActionController::Base
  def hello
    render :text => "Hello World<br/>LOAD_PATH:#{$LOAD_PATH}<br/>Gem.path:#{Gem.path}"
  end
end

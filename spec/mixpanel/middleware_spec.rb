require 'spec_helper'

describe Middleware do
  include Rack::Test::Methods

  describe "Dummy apps, no text/html" do
    before do
      setup_rack_application(DummyApp)
      get "/"
    end

    it "should pass through if the document is not text/html content type" do
      last_response.body.should == DummyApp.new.body
    end
  end

  describe "Appending mixpanel scripts" do
    before do
      setup_rack_application(HtmlApp)
      get "/"
    end

    it "should append mixpanel scripts to head element" do
      Nokogiri::HTML(last_response.body).search('head script').should_not be_empty
      Nokogiri::HTML(last_response.body).search('body script').should be_empty
    end

    it "should have 2 included scripts" do
      Nokogiri::HTML(last_response.body).search('script').size.should == 2
    end

    it "should use the specified token instantiating mixpanel lib" do
      last_response.should =~ /new MixpanelLib\('#{MIX_PANEL_TOKEN}'\)/
    end

    it "should define Content-Length if not exist" do
      last_response.headers.has_key?("Content-Length").should == true
    end

    it "should update Content-Length in headers" do
      last_response.headers["Content-Length"].should_not == HtmlApp.new.body.length
    end
  end

  describe "Tracking appended events" do
    before do
      callback = lambda do |env|
        mixpanel = Mixpanel.new(MIX_PANEL_TOKEN, env)
        mixpanel.append_event("Visit", {:article => 1})
        mixpanel.append_event("Sign in")
      end

      setup_rack_application(HtmlAppWithEvents, :callback => callback)

      get "/"
    end

    it "should be tracking the correct events" do
      last_response.body.should =~ /mpmetrics\.track\("Visit",\s?\{"article":1\}\)/
      last_response.body.should =~ /mpmetrics\.track\("Sign in",\s?\{\}\)/
    end
  end
end

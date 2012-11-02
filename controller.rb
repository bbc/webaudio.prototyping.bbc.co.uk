require 'nokogiri'

layout 'layout.html.erb'

ignore /Gemfile.*/
ignore /Rakefile/
ignore /Guardfile/
# coding: utf-8

ignore /src/
ignore /.git/
ignore /.gitignore/

helpers do
  def extract_code_for(fn)
    fn = File.expand_path(File.join(File.dirname(__FILE__), fn))
    doc = File.open(fn) do |f|
      Nokogiri::HTML(f)
    end
    doc.css("table").to_html
  end

  def git_version_number
    `git log | sed -n 1p`.split(" ").last
  end

  def url(page='')
    "http%3A%2F%2Fwebaudio.prototyping.bbc.co.uk%2F#{page}"
  end
end

before 'index.html.erb' do
  layout 'layout.html.erb'
  @machine = "about"
  @show_prev_next_buttons = false
  @url = url() # index page 
end

before 'wobbulator.html.erb' do
  @code = extract_code_for("docs/wobbulator.html")
  @machine = "wobbulator"
  @url = url("#{@machine}.html")
end

before 'ring-modulator.html.erb' do
  @code = extract_code_for("docs/ring-modulator.html")
  @machine = "ring-modulator"
  @url = url("#{@machine}.html")
end

before 'gunfire.html.erb' do
  @code = extract_code_for("docs/gunfire.html")
  @machine = "gunfire"
  @url = url("#{@machine}.html")
end

before 'tapeloops.html.erb' do
  @code = extract_code_for("docs/tapeloops.html")
  @machine = "tapeloops"
  @url = url("#{@machine}.html")
end

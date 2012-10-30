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
end

before 'index.html.erb' do
  layout 'landing_layout.html.erb'
  @machine = "index"
end

before 'about.html.erb' do
  layout 'layout.html.erb'
  @machine = "about"
  @show_prev_next_buttons = false
end

before 'wobbulator.html.erb' do
  @code = extract_code_for("docs/wobbulator.html")
  @machine = "wobbulator"
end

before 'ring-modulator.html.erb' do
  @code = extract_code_for("docs/ring-modulator.html")
  @machine = "ring-modulator"
end

before 'gunshot.html.erb' do
  @code = extract_code_for("docs/gunshot.html")
  @machine = "gunshot"
end

before 'tapeloops.html.erb' do
  @code = extract_code_for("docs/tapeloops.html")
  @machine = "tapeloops"
end

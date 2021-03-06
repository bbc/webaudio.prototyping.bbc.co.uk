require 'nokogiri'

layout 'layout.html.erb'

ignore /.git/
ignore /.gitignore/
ignore /.ruby-version/
ignore /COPYING/
ignore /Gemfile.*/
ignore /Makefile/
ignore /README/
ignore /package.json/
ignore /package-lock.json/
ignore /requirements.txt/
ignore /screenshot.png/
ignore /node_modules/
ignore /src/

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

  def encoded_url(page='')
    "https%3A%2F%2Fwebaudio.prototyping.bbc.co.uk%2F#{page}"
  end
end

before 'index.html.erb' do
  layout 'layout.html.erb'
  @machine = "about"
  @show_prev_next_buttons = false
  @encoded_url = encoded_url() # index page
  @title = "Recreating the sounds of the BBC Radiophonic Workshop"
end

before 'credits.html.erb' do
  layout 'layout.html.erb'
  @machine = "credits"
  @show_prev_next_buttons = false
  @encoded_url = encoded_url() # index page
  @title = "Recreating the sounds of the BBC Radiophonic Workshop"
end

before 'wobbulator/index.html.erb' do
  @code = extract_code_for("docs/wobbulator.html")
  @machine = "wobbulator"
  @encoded_url = encoded_url(@machine)
  @title = "Wobbulator : Recreating the sounds of the BBC Radiophonic Workshop"
end

before 'ring-modulator/index.html.erb' do
  @code = extract_code_for("docs/ring-modulator.html")
  @machine = "ring-modulator"
  @encoded_url = encoded_url(@machine)
  @title = "Ring Modulator : Recreating the sounds of the BBC Radiophonic Workshop"
end

before 'gunfire/index.html.erb' do
  @code = extract_code_for("docs/gunfire.html")
  @machine = "gunfire"
  @encoded_url = encoded_url(@machine)
  @title = "Gunfire Effects : Recreating the sounds of the BBC Radiophonic Workshop"
end

before 'tapeloops/index.html.erb' do
  @code = extract_code_for("docs/tapeloops.html")
  @machine = "tapeloops"
  @encoded_url = encoded_url(@machine)
  @title = "Tape Loops : Recreating the sounds of the BBC Radiophonic Workshop"
end

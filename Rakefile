require 'nokogiri'

desc "Generate documentation"
task :docs do
  system("docco src/*.coffee")
end

def doc_from_file(fn)
  f = File.open(fn)
  doc = Nokogiri::HTML(f)
  f.close
  doc
end

def git_version_number
  `git log | sed -n 1p`.split(" ").last
end

def version_js
  "require.config({ urlArgs: \"version=#{git_version_number}\" });"
end

def update_version_number(source)
  source.css("script#version").children.first.content = version_js
  source
end

desc "Replace the documentation in the application HTML files with generated docs"
task :build_wobbulator do
  source = doc_from_file("wobbulator/template.html")

  # Update the version number for require.js
  source = update_version_number(source)

  # Load the docco documentation
  documentation = doc_from_file("docs/wobbulator.html")

  # Replace the documentation table in the template with the one from
  # the docco doc
  new_doc_div_contents = documentation.css("table")
  old_doc_div = source.css("#code").first

  old_doc_div.children.remove
  old_doc_div.add_child(new_doc_div_contents)

  # Write out index.html
  File.open("wobbulator/index.html", 'w') {|f| f.write(source.to_xml) }
  puts "wobbulator/index.html generated"
end

task :build => [:docs, :build_wobbulator]

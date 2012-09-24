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

desc "Replace the documentation in the application HTML files with generated docs"
task :build_wobbulator do
  documentation = doc_from_file("docs/wobbulator.html")
  source = doc_from_file("wobbulator/template.html")

  new_doc_div_contents = documentation.css("table")
  old_doc_div = source.css("#code").first

  old_doc_div.children.remove
  old_doc_div.add_child(new_doc_div_contents)

  File.open("wobbulator/index.html", 'w') {|f| f.write(source.to_xml) }
  puts "Wobbulator code documentation generated"
end

task :build => [:docs, :build_wobbulator]

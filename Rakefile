require 'nokogiri'

desc "Generate documentation"
task :docs do
  system("docco src/*.coffee")
end

desc "Generate js from coffeescript"
task :coffee do
  system("coffee -c -o js/ src/")
end

desc "Run stasis"
task :stasis do
  system("bundle exec stasis")
end

task :build => [:coffee, :docs, :stasis]

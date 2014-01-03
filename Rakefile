require "bundler/gem_tasks"
require "rake/testtask"

task default: :test

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = 'test/*_test.rb'
end

def code_from_markdown file
  content = File.read(file)
  code_snippets = []
  content.scan(/`{3,}ruby\n((.|\n)*?)^`{3,}/) { |m| code_snippets << $1 }
  code_snippets
end

task :executable_docs do
  lib = File.expand_path("../lib", __FILE__)
  $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
  require "deprecator"

  examples = code_from_markdown("./README.md")
  examples.each { |example|
    eval example
  }
end

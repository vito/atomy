$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "atomy/version"
 
desc "Run the specs and tests."
task :default => [:spec, :test]

desc "Build a new gem."
task :build do
  sh "gem build atomy.gemspec"
end
 
desc "Build and install Atomy."
task :install => :build do
  sh "gem install atomy-#{Atomy::VERSION}"
end

desc "Uninstall Atomy."
task :uninstall do
  sh "gem uninstall atomy --executables"
end

desc "Uninstall and then install Atomy."
task :reinstall => [:uninstall, :install]

desc "Push a new Atomy version."
task :release => :build do
  sh "gem push atomy-#{Atomy::VERSION}.gem"
end

desc "Regenrate parser."
task :parser do
  sh "kpeg -f -s lib/atomy/atomy.kpeg"
end

desc "Clean up .ayc files."
task :clean do
  sh "find . -name '*.ayc' -delete"
end

desc "Run the lower-level specs."
task :spec do
  sh "rbx spec/main.rb"
end

desc "Run the higher-level tests."
task :test do
  sh "./bin/atomy test/main.ay"
end

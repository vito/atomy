$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "atomy/version"
 
desc "Run the specs and tests."
task :default => [:spec, :test]

desc "Build a new gem."
task :build do
  system "gem build atomy.gemspec"
end
 
desc "Build and install Atomy."
task :install => :build do
  system "gem install atomy-#{Atomy::VERSION}"
end

desc "Uninstall Atomy."
task :uninstall do
  system "gem uninstall atomy --executables"
end

desc "Uninstall and then install Atomy."
task :reinstall => [:uninstall, :install]

desc "Push a new Atomy version."
task :release => :build do
  system "gem push atomy-#{Atomy::VERSION}"
end

desc "Regenrate parser."
task :parser do
  system "kpeg -f -s lib/atomy/atomy.kpeg"
end

desc "Clean up .ayc files."
task :clean do
  system "find . -name '*.ayc' -delete"
end

desc "Run the lower-level specs."
task :spec do
  system "rbx spec/main.rb"
end

desc "Run the higher-level tests."
task :test do
  system "rbx -X19 ./bin/atomy test/main.ay"
end

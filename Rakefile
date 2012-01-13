task :default => :test

task :parser do
  sh "kpeg -f -s lib/atomy/atomy.kpeg"
end

task :formatter do
  sh "kpeg -f -s lib/atomy/formatter.kpeg"
end

task :clean do
  sh "find . -name '*.ayc' -delete"
end

task :install do
  sh "rm *.gem; rbx -S gem uninstall atomy; rbx -S gem build atomy.gemspec; rbx -S gem install atomy-*.gem --no-ri --no-rdoc"
end

task :reference do
  sh "rbx -X19 ./bin/atomy -d docs/reference -s exit"
end

task :docs do
  sh "rbx -X19 ./bin/atomy ../doodle/bin/doodle docs/index.ddl -o _doodle"
end

task :sync_docs do
  sh "rsync -a -P -e \"ssh -p 7331\" _doodle/ alex@atomy-lang.org:/srv/http/atomy-lang.org/site/docs/"
end

task :spec do
  sh "rbx spec/main.rb"
end

task :test => :spec do
  sh "rbx -X19 ./bin/atomy test/main.ay"
end

task :parser do
  sh "kpeg -f -s lib/atomy.kpeg"
end

task :formatter do
  sh "kpeg -f -s lib/formatter.kpeg"
end

task :clean do
  sh "find . -name '*.rbc' -delete; find . -name '*.ayc' -delete"
end

task :install do
  sh "rbx -S gem uninstall atomy; rbx -S gem build atomy.gemspec; rbx -S gem install atomy-*.gem --no-ri --no-rdoc"
end

task :docs do
  sh "./bin/atomy -d docs/reference -s exit"
  sh "./bin/atomy ../doodle/bin/doodle docs/reference.ddl -o doodle"
end

task :sync_docs do
  sh "rsync -a -P -e \"ssh -p 7331\" doodle/ alex@atomo-lang.org:/srv/http/atomo-lang.org/site/docs/atomy/"
end

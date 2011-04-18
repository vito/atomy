task :parser do
  sh "kpeg -f -s lib/atomy.kpeg"
end
end

task :clean do
  sh "find . -name '*.rbc' -delete; find . -name '*.ayc' -delete"
end

task :install do
  sh "rbx -S gem uninstall atomy; rbx -S gem build atomy.gemspec; rbx -S gem install atomy-*.gem --no-ri --no-rdoc"
end

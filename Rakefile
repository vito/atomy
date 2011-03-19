task :parser do
  sh "kpeg -f -s -n Atomo::Parser lib/atomo/atomo.kpeg"
end

task :clean do
  sh "find . -name '*.rbc' -delete; find . -name '*.atomoc' -delete"
end

task :install do
  sh "rbx -S gem uninstall atomo; rbx -S gem build atomo.gemspec; rbx -S gem install atomo-*.gem --no-ri --no-rdoc"
end

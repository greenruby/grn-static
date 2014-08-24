desc "rsync to server"
task :upload do
  system "rsync -av --stats --delete site/ moseweb:/srv/greenruby.org"
end

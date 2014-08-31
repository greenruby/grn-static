desc "rsync to server"
task :upload do
  #system "rsync -av --stats --delete site/ moseweb:/srv/greenruby.org"
  system "rsync -av --stats site/ duo:web/grn-static/site"
end

desc "rsync to server"
task :upload do
  #system "rsync -av --stats --delete site/ moseweb:/srv/greenruby.org"
  system "rsync -av --stats --delete site/ moseweb:web/mose.fr/grn-static/site"
end

require_relative '../../lib/builder'

namespace :generate do

  desc "generate a new letter html file"
  task :letter do
    builder = Greeby::Builder.new
    builder.make_letter('grn.yml')
    builder.make_archives('grn.yml')
    builder.make_web
    builder.make_rss
  end

  desc "re-generate all letters html file"
  task :all do
    builder = Greeby::Builder.new
    builder.make_all
  end

  desc "updates static website"
  task :web do
    builder = Greeby::Builder.new
    builder.make_web
  end

  desc "make rss feed"
  task :rss do
    builder = Greeby::Builder.new
    builder.make_rss
  end

  desc "full regeneration"
  task :full do
    Rake::Task["generate:letter"].invoke
    Rake::Task["generate:all"].invoke
  end

  desc "creates json files"
  task :json do
    builder = Greeby::Builder.new
    builder.make_json
  end

  desc "creates json files (small)"
  task :json_small do
    builder = Greeby::Builder.new
    builder.make_json_small
  end

  desc "creates json files (array)"
  task :json_array do
    builder = Greeby::Builder.new
    builder.make_json_array
  end
end

task :generate do
  Rake::Task["generate:full"].invoke
end

task :letter do
  Rake::Task["generate:letter"].invoke
end

task default: :generate

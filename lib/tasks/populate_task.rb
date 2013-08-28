require_relative '../../lib/store'

namespace :populate do

  desc "check mongo connection"
  task :check do
    @store = Greeby::Store.new
  end

end
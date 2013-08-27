module Greeby
  class Store

    def initialize
      @db = Mongo::Connection.new.db("organews", pool_size: 5, timeout: 5)
    end

  end
end
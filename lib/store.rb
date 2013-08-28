require "bson"

module Greeby
  class Store

    def initialize
      @db = Mongo::Connection.new.db("organews", pool_size: 5, timeout: 5)
    end

    def list

    end
    
    def tobsonid(id)
      BSON::ObjectId(id)
    end

    def frombsonid(obj)
      obj.merge({'id' => obj['_id'].to_s})
    end

  end
end
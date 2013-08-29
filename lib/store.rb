require "bson"

module Greeby
  class Store

    def initialize
      @mongo = MongoClient.new("localhost", pool_size: 5, timeout: 5)
      @db = @mongo.db("organews")
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
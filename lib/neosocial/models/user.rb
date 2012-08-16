class User
  attr_reader :neo_id
  attr_accessor :uid, :name, :image_url, :location, :token

  def initialize(node)
    @neo_id     = node["self"].split('/').last
    @uid        = node["data"]["uid"]
    @name       = node["data"]["name"]
    @image_url  = node["data"]["img_url"]
    @location   = node["data"]["location"]
    @token      = node["data"]["token"]
  end

  def self.find_by_uid(uid)
    user = $neo_server.get_node_index("user_index", "uid", uid)

    if user
      User.new(user.first)
    else
      nil
    end
  end

  def self.create_with_omniauth(auth)
    values = {"name"      => auth.info.name,
              "image_url" => auth.info.image,
              "location"  => auth.info.location,
              "uid"       => auth.uid,
              "token"     => auth.credentials.token}
    node = $neo_server.create_unique_node("user_index", "uid", auth.uid, values)

    Sidekiq::Client.enqueue(Job::ImportFacebookProfile, auth.uid)
    User.new(node)
  end

  def self.create_from_facebook(friend)
    id        = friend["id"]
    name      = friend["name"]
    location  = friend["location"] ? (friend["location"]["name"] || "") : ""
    image_url = "https://graph.facebook.com/#{friend["id"]}/picture"

    node = $neo_server.create_unique_node("user_index", "uid", id,
                                          {"name"      => name,
                                           "location"  => location,
                                           "image_url" => image_url,
                                           "uid"       => id
                                          })
    User.new(node)
  end

  def client
    @client ||= Koala::Facebook::API.new(self.token)
  end

  def add_like(like_id)
    like = Like.get_by_id(like_id)
    $neo_server.create_unique_relationship("has_index", "user_value",  "#{@uid}-#{like["data"]["name"]}", "has", @neo_id, Like.neo_id(like))
  end

  def likes
    cypher = "START me = node(#{@neo_id})
              MATCH me -[:likes]-> like
              RETURN ID(like), like.name"
    results = $neo_server.execute_query(cypher)
    Array(results["data"])
  end

  def likes_count
    cypher = "START me = node(#{@neo_id})
              MATCH me -[:likes]-> like
              RETURN COUNT(like)"
    results = $neo_server.execute_query(cypher)

    if results["data"][0]
      results["data"][0][0]
    else
      0
    end
  end

  def friends
    cypher = "START me = node(#{@neo_id})
              MATCH me -[:friends]-> friend
              RETURN friend.uid, friend.name, friend.image_url"
    results = $neo_server.execute_query(cypher)

    Array(results["data"])
  end

  def friends_count
    cypher = "START me = node(#{@neo_id})
              MATCH me -[:friends]-> friend
              RETURN COUNT(friend)"
    results = $neo_server.execute_query(cypher)

    if results["data"][0]
      results["data"][0][0]
    else
      0
    end

  end

end
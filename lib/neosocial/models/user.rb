class User

  def self.find_by_uid(uid)
    user = $neo_server.get_node_index("user_index", "uid", uid)

    if user
      user.first
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
    node
  end

  def self.create_from_facebook(friend)
    id        = friend["id"]
    name      = friend["name"]
    location  = friend["location"] ? friend["location"]["name"] : ""
    image_url = "https://graph.facebook.com/#{friend["id"]}/picture"

    node = $neo_server.create_unique_node("user_index", "uid", id,
                                          {"name"      => name,
                                           "location"  => location,
                                           "image_url" => image_url,
                                           "uid"       => id
                                          })
    node
  end

  def self.neo_id(node)
    node["self"].split('/').last
  end

  def self.client(node)
    @client ||= Koala::Facebook::API.new(node["data"]["token"])
  end

  def self.add_like(node, like_id)
    like = Like.get_by_id(like_id)
    $neo_server.create_unique_relationship("has_index", "user_value",  "#{node["data"]["uid"]}-#{like["data"]["name"]}", "has", User.neo_id(node), Like.neo_id(like))
  end

  def self.likes(node)
    cypher = "START me = node(#{User.neo_id(node)})
              MATCH me -[:likes]-> like
              RETURN ID(like), like.name"
    results = $neo_server.execute_query(cypher)
    Array(results["data"])
  end

  def self.likes_count(node)
    cypher = "START me = node(#{User.neo_id(node)})
              MATCH me -[:likes]-> like
              RETURN COUNT(like)"
    results = $neo_server.execute_query(cypher)

    if results["data"][0]
      results["data"][0][0]
    else
      0
    end
  end

  def self.friends(node)
    cypher = "START me = node(#{User.neo_id(node)})
              MATCH me -[:friends]-> friend
              RETURN friend.uid, friend.name, friend.image_url"
    results = $neo_server.execute_query(cypher)

    Array(results["data"])
  end

  def self.friends_count(node)
    cypher = "START me = node(#{User.neo_id(node)})
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
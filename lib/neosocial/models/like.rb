class Like < Neography::Node

  def self.get_by_id(id)
    results = $neo_server.get_node(id)
    results
  end

  def self.find_by_uid(uid)
    like = $neo_server.get_node_index("likes_index", "uid", uid)

    if like
      like.first
    else
      nil
    end
  end

  def self.neo_id(node)
    node["self"].split('/').last
  end

  def self.available
    cypher = "START users = node:user_index('uid:*')
              MATCH users -[:likes]-> like
              RETURN DISTINCT ID(like), like.name, COUNT(like) AS user_count
              ORDER BY user_count DESC"
    results = $neo_server.execute_query(cypher)

    if results
      results["data"]
    else
      []
    end
  end

  def self.users(node)
    cypher = "START me = node(#{Like.neo_id(node)})
              MATCH me <-[:likes]- users
              RETURN users.uid, users.name, users.image_url"
    results = $neo_server.execute_query(cypher)
    results["data"]
  end

  def self.users_count(node)
    cypher = "START me = node(#{Like.neo_id(node)})
              MATCH me <-[:likes]-> users
              RETURN COUNT(users)"
    results = $neo_server.execute_query(cypher)
    results["data"][0][0]
  end

end
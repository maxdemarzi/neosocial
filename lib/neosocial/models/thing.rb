class Thing
  attr_reader :neo_id
  attr_accessor :uid, :name

  def initialize(node)
    @neo_id     = node["self"].split('/').last
    @uid        = node["data"]["uid"]
    @name       = node["data"]["name"]
  end

  def self.get_by_id(id)
    Thing.new($neo_server.get_node(id))
  end

  def self.find_by_uid(uid)
    thing = $neo_server.get_node_index("thing_index", "uid", uid)

    if thing
      Thing.new(thing.first)
    else
      nil
    end
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

  def users
    cypher = "START me = node(#{@neo_id})
              MATCH me <-[:likes]- users
              RETURN users.uid, users.name, users.image_url"
    results = $neo_server.execute_query(cypher)
    results["data"]
  end

  def users_count
    cypher = "START me = node(#{@neo_id})
              MATCH me <-[:likes]-> users
              RETURN COUNT(users)"
    results = $neo_server.execute_query(cypher)
    results["data"][0][0]
  end

end
module Job
  class ImportFriends
    include Sidekiq::Worker

    def perform(uid, person_id)
      @neo = Neography::Rest.new
      user = User.find_by_uid(uid)
      client = User.client(user)
      person = client.get_object(person_id)
      friend = User.create_from_facebook(person)

      # Make them friends
      commands = []
      commands << [:create_unique_relationship, "friends_index", "ids",  "#{uid}-#{person_id}", "friends", user, friend]
      commands << [:create_unique_relationship, "friends_index", "ids",  "#{person_id}-#{uid}", "friends", friend, user]
      batch_result = @neo.batch *commands

      # Import mutual friends
      mutual_friends = client.get_connections("me", "mutualfriends/#{person_id}")


      # Import friend likes
      likes = client.get_connections(person_id, "likes")

      if likes
        # Import things
        commands = []
        likes.each do |thing|
          commands << [:create_unique_node, "thing_index", "uid", thing["id"], {"uid" => thing["id"], "name" => thing["name"] }]
        end
        batch_result = @neo.batch *commands

        # Connect the user to these things
        commands = []
        batch_result.each do |b|
          commands << [:create_unique_relationship, "likes_index", "user_thing",  "#{person_id}-#{b["body"]["data"]["uid"]}", "likes", friend, b["body"]["self"].split("/").last]
        end
        @neo.batch *commands
      end

    end

  end
end
module Job
  class ImportFacebookProfile
    include Sidekiq::Worker

    def perform(uid)
      @neo = Neography::Rest.new
      user = User.find_by_uid(uid)

      client = User.client(user)
      likes = client.get_connections("me", "likes")

      if likes
        # Import likes
        commands = []
        likes.each do |thing|
          commands << [:create_unique_node, "thing_index", "uid", thing["id"], {"uid" => thing["id"], "name" => thing["name"] }]
        end
        batch_result = @neo.batch *commands

        # Connect the user to these things
        commands = []
        batch_result.each do |b|
          commands << [:create_unique_relationship, "likes_index", "user_thing",  "#{uid}-#{b["body"]["data"]["uid"]}", "likes", user, b["body"]["self"].split("/").last]
        end
        @neo.batch *commands
      end

      # Import Friends
      friends = client.get_connections("me", "friends")
      friends.each do |friend|
        Sidekiq::Client.enqueue(Job::ImportFriends, uid, friend["id"])
        Job::ImportMutualFriends.perform_at(120, uid, friend["id"])
      end
    end

  end
end
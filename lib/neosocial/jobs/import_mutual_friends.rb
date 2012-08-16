module Job
  class ImportMutualFriends
    include Sidekiq::Worker

    def perform(uid, person_id)
      @neo = Neography::Rest.new
      user = User.find_by_uid(uid)
      client = User.client(user)
      person = client.get_object(person_id)
      friend = User.create_from_facebook(person)

      # Import mutual friends
      mutual_friends = client.get_connections("me", "mutualfriends/#{person_id}")

      commands = []

      # Make them friends
      mutual_friends.each do |mutual_friend|
        uid = mutual_friend["id"]

        node = User.find_by_uid(uid)
        unless node
          person = client.get_object(uid)
          node = User.create_from_facebook(person)
        end

        commands << [:create_unique_relationship, "friends_index", "ids",  "#{uid}-#{person_id}", "friends", node, friend]
        commands << [:create_unique_relationship, "friends_index", "ids",  "#{person_id}-#{uid}", "friends", friend, node]

      end

      batch_result = @neo.batch *commands
    end

  end
end
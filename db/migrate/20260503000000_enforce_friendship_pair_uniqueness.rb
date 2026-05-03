class EnforceFriendshipPairUniqueness < ActiveRecord::Migration[8.0]
  def up
    remove_index :friendships, name: "index_friendships_on_requester_id_and_addressee_id"

    add_index :friendships,
              "LEAST(requester_id, addressee_id), GREATEST(requester_id, addressee_id)",
              unique: true,
              name: "index_friendships_on_user_pair"
  end

  def down
    remove_index :friendships, name: "index_friendships_on_user_pair"

    add_index :friendships,
              [ :requester_id, :addressee_id ],
              unique: true,
              name: "index_friendships_on_requester_id_and_addressee_id"
  end
end

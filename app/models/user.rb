class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  validates :google_sub, uniqueness: true, allow_nil: true

  has_many :sent_messages,
           class_name: "Message",
           foreign_key: :sender_id,
           dependent: :destroy,
           inverse_of: :sender
  has_many :received_messages,
           class_name: "Message",
           foreign_key: :recipient_id,
           dependent: :destroy,
           inverse_of: :recipient

  has_many :requested_friendships,
           class_name: "Friendship",
           foreign_key: :requester_id,
           dependent: :destroy,
           inverse_of: :requester
  has_many :received_friendships,
           class_name: "Friendship",
           foreign_key: :addressee_id,
           dependent: :destroy,
           inverse_of: :addressee
end

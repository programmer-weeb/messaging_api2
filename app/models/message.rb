class Message < ApplicationRecord
  belongs_to :sender, class_name: "User", inverse_of: :sent_messages
  belongs_to :recipient, class_name: "User", inverse_of: :received_messages

  validates :body, presence: true, length: { maximum: 1_000 }
end

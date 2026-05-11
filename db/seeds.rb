# This seed creates a large, repeatable dataset for local API development.
# It only replaces seed-managed records scoped to the generated seed users.

SEED_PASSWORD = ENV.fetch("SEED_PASSWORD", "Password123!")
USER_COUNT = ENV.fetch("SEED_USER_COUNT", "150").to_i
FRIENDSHIP_COUNT = ENV.fetch("SEED_FRIENDSHIP_COUNT", "1200").to_i
MESSAGE_COUNT = ENV.fetch("SEED_MESSAGE_COUNT", "8000").to_i

EMAIL_DOMAIN = "seed.messaging.local"
BODY_OPENERS = [
  "Quick update",
  "Checking in",
  "Heads up",
  "Following up",
  "Status note",
  "Reminder",
  "Context",
  "FYI"
].freeze
BODY_TOPICS = [
  "about the onboarding flow",
  "for the weekend plan",
  "before the release window",
  "on the support issue",
  "for the conversation view",
  "around the API changes",
  "after the last message",
  "for tomorrow morning"
].freeze
BODY_CLOSERS = [
  "Reply when you can.",
  "No rush.",
  "Let me know what you think.",
  "I will follow up later.",
  "This should be enough for now.",
  "We can sort the rest out in chat."
].freeze

def seed_email(index)
  format("seed_user_%03d@%s", index + 1, EMAIL_DOMAIN)
end

def timestamp_between(from:, to:)
  Time.at(rand(from.to_f..to.to_f)).utc
end

def message_body(sequence)
  [
    "#{BODY_OPENERS.sample} ##{sequence}",
    BODY_TOPICS.sample,
    BODY_CLOSERS.sample
  ].join(" ")
end

def in_batches(records, size: 1_000)
  records.each_slice(size) { |slice| yield slice }
end

def friendship_status
  roll = rand
  return Friendship.statuses[:accepted] if roll < 0.65
  return Friendship.statuses[:pending] if roll < 0.95

  Friendship.statuses[:blocked]
end

users = []
friendship_rows = []
message_rows = []

ActiveRecord::Base.transaction do
  USER_COUNT.times do |index|
    email = seed_email(index)
    user = User.find_or_initialize_by(email: email)
    if user.new_record?
      user.password = SEED_PASSWORD
      user.password_confirmation = SEED_PASSWORD
      user.save!
    end
    users << user
  end

  seed_user_ids = users.map(&:id)

  Message.where(sender_id: seed_user_ids, recipient_id: seed_user_ids).delete_all
  Friendship.where(requester_id: seed_user_ids, addressee_id: seed_user_ids).delete_all

  all_pairs = users.combination(2).to_a
  raise "Not enough distinct user pairs for requested friendships." if FRIENDSHIP_COUNT > all_pairs.size

  friendship_pairs = all_pairs.sample(FRIENDSHIP_COUNT)
  friendship_rows = friendship_pairs.map do |left_user, right_user|
    requester, addressee = [ [ left_user, right_user ], [ right_user, left_user ] ].sample
    created_at = timestamp_between(from: 9.months.ago, to: 2.weeks.ago)
    updated_at = timestamp_between(from: created_at, to: Time.current)

    {
      requester_id: requester.id,
      addressee_id: addressee.id,
      status: friendship_status,
      created_at: created_at,
      updated_at: updated_at
    }
  end

  in_batches(friendship_rows) { |slice| Friendship.insert_all!(slice) }

  accepted_pair_ids = Friendship
    .accepted
    .where(requester_id: seed_user_ids, addressee_id: seed_user_ids)
    .pluck(:requester_id, :addressee_id)
  accepted_pairs = accepted_pair_ids.flat_map { |requester_id, addressee_id| [ [ requester_id, addressee_id ], [ addressee_id, requester_id ] ] }
  message_pairs = accepted_pairs.presence || friendship_rows.flat_map { |row| [ [ row[:requester_id], row[:addressee_id] ], [ row[:addressee_id], row[:requester_id] ] ] }

  message_rows = Array.new(MESSAGE_COUNT) do |index|
    sender_id, recipient_id = message_pairs.sample
    created_at = timestamp_between(from: 6.months.ago, to: Time.current)

    {
      sender_id: sender_id,
      recipient_id: recipient_id,
      body: message_body(index + 1),
      created_at: created_at,
      updated_at: created_at
    }
  end

  in_batches(message_rows) { |slice| Message.insert_all!(slice) }
end

puts <<~SUMMARY
  Seed complete.
  Users: #{users.count}
  Friendships: #{friendship_rows.count}
  Messages: #{message_rows.count}
  Seed user password: #{SEED_PASSWORD}
  Example user: #{users.first.email}
SUMMARY

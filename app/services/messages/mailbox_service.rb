module Messages
  class MailboxService
    def initialize(current_user:)
      @current_user = current_user
    end

    def visible_messages
      Message
        .includes(:sender, :recipient)
        .where(sender: current_user)
        .or(Message.where(recipient: current_user))
    end

    def inbox
      visible_messages.order(created_at: :desc)
    end

    def sent
      current_user.sent_messages.includes(:recipient).order(created_at: :desc)
    end

    def received
      current_user.received_messages.includes(:sender).order(created_at: :desc)
    end

    def conversations
      inbox.group_by { |message| conversation_partner(message).id }.map do |_partner_id, conversation_messages|
        partner = conversation_partner(conversation_messages.first)

        {
          user: partner,
          latest_message: conversation_messages.first,
          messages_count: conversation_messages.size
        }
      end
    end

    def conversation_with(other_user)
      Message
        .includes(:sender, :recipient)
        .where(sender: current_user, recipient: other_user)
        .or(Message.where(sender: other_user, recipient: current_user))
        .order(:created_at)
    end

    def create_message(attributes)
      current_user.sent_messages.create(attributes)
    end

    def participant?(message)
      message.sender_id == current_user.id || message.recipient_id == current_user.id
    end

    def sender?(message)
      message.sender_id == current_user.id
    end

    private

    attr_reader :current_user

    def conversation_partner(message)
      message.sender_id == current_user.id ? message.recipient : message.sender
    end
  end
end

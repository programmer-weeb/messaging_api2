class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_message, only: [ :show, :destroy ]
  before_action :authorize_participant!, only: :show
  before_action :authorize_sender!, only: :destroy
  before_action :set_mailbox_service

  def index
    messages = @mailbox_service.inbox

    render json: { messages: messages.map { |message| message_payload(message) } }, status: :ok
  end

  def sent
    messages = @mailbox_service.sent

    render json: { messages: messages.map { |message| message_payload(message) } }, status: :ok
  end

  def received
    messages = @mailbox_service.received

    render json: { messages: messages.map { |message| message_payload(message) } }, status: :ok
  end

  def conversations
    conversations = @mailbox_service.conversations.map do |conversation|
      {
        user: user_payload(conversation[:user]),
        latest_message: message_payload(conversation[:latest_message]),
        messages_count: conversation[:messages_count]
      }
    end

    render json: { conversations: conversations }, status: :ok
  end

  def conversation
    other_user = User.find(params[:user_id])
    messages = @mailbox_service.conversation_with(other_user)

    render json: {
      user: user_payload(other_user),
      messages: messages.map { |message| message_payload(message) }
    }, status: :ok
  end

  def show
    render json: { message: message_payload(@message) }, status: :ok
  end

  def create
    message = @mailbox_service.create_message(message_params)

    if message.persisted?
      render json: { message: message_payload(message) }, status: :created
    else
      render_unprocessable(message)
    end
  end

  def destroy
    @message.destroy
    head :no_content
  end

  private

  def set_message
    @message = Message.includes(:sender, :recipient).find(params[:id])
  end

  def set_mailbox_service
    @mailbox_service = Messages::MailboxService.new(current_user: current_user)
  end

  def authorize_participant!
    return if @mailbox_service.participant?(@message)

    render_forbidden
  end

  def authorize_sender!
    return if @mailbox_service.sender?(@message)

    render_forbidden("Only sender can delete this message.")
  end

  def message_params
    params.require(:message).permit(:recipient_id, :body)
  end

  def message_payload(message)
    {
      id: message.id,
      body: message.body,
      created_at: message.created_at,
      updated_at: message.updated_at,
      sender: user_payload(message.sender),
      recipient: user_payload(message.recipient)
    }
  end

  def user_payload(user)
    {
      id: user.id,
      email: user.email
    }
  end
end

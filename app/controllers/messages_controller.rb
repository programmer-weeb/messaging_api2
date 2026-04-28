class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_message, only: [ :show, :destroy ]
  before_action :authorize_participant!, only: :show
  before_action :authorize_sender!, only: :destroy

  def index
    messages = visible_messages.order(created_at: :desc)

    render json: { messages: messages.map { |message| message_payload(message) } }, status: :ok
  end

  def sent
    messages = current_user.sent_messages.includes(:recipient).order(created_at: :desc)

    render json: { messages: messages.map { |message| message_payload(message) } }, status: :ok
  end

  def received
    messages = current_user.received_messages.includes(:sender).order(created_at: :desc)

    render json: { messages: messages.map { |message| message_payload(message) } }, status: :ok
  end

  def conversations
    messages = visible_messages.includes(:sender, :recipient).order(created_at: :desc)
    grouped = messages.group_by { |message| conversation_partner_id(message) }

    conversations = grouped.map do |partner_id, conversation_messages|
      partner = conversation_partner(conversation_messages.first)
      latest_message = conversation_messages.first

      {
        user: user_payload(partner),
        latest_message: message_payload(latest_message),
        messages_count: conversation_messages.size
      }
    end

    render json: { conversations: conversations }, status: :ok
  end

  def conversation
    other_user = User.find(params[:user_id])
    messages = Message
               .includes(:sender, :recipient)
               .where(sender: current_user, recipient: other_user)
               .or(Message.where(sender: other_user, recipient: current_user))
               .order(:created_at)

    render json: {
      user: user_payload(other_user),
      messages: messages.map { |message| message_payload(message) }
    }, status: :ok
  end

  def show
    render json: { message: message_payload(@message) }, status: :ok
  end

  def create
    message = current_user.sent_messages.build(message_params)

    if message.save
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

  def authorize_participant!
    return if @message.sender_id == current_user.id || @message.recipient_id == current_user.id

    render_forbidden
  end

  def authorize_sender!
    return if @message.sender_id == current_user.id

    render_forbidden("Only sender can delete this message.")
  end

  def visible_messages
    Message
      .includes(:sender, :recipient)
      .where(sender: current_user)
      .or(Message.where(recipient: current_user))
  end

  def conversation_partner(message)
    message.sender_id == current_user.id ? message.recipient : message.sender
  end

  def conversation_partner_id(message)
    conversation_partner(message).id
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

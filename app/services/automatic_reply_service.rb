class AutomaticReplyService

  # @param phone_number [String] The customer's phone number
  # @return [Boolean] Weather an automatic reply should be sent
  # We should send automatic reply if:
  # 1. It's a new customer (no human record)
  # 2. It's an existing customer with no open conversation
  def self.should_send_automatic_reply?(phone_number)
    human = Human.find_by_phone_number(phone_number)
    open_conversation = Conversation.find_open_by_customer_phone_number(phone_number)
    open_conversation.nil?
  end

  # @param phone_number [String] The customer's phone number
  # @return [String] The type of automatic reply to send
  def self.determine_reply_type(phone_number)
    human = Human.find_by_phone_number(phone_number)
    human.nil? ? 'new_customer' : 'existing_customer'
  end


  # @param conversation [Conversation] The conversation to send the reply to
  # @param reply_type [String] The type of automatic reply to send
  # @return [Boolean] Whether the reply was sent successfully
  def self.send_automatic_reply(conversation, reply_type)
    if reply_type == 'existing_customer'
      profile_url = Rails.application.routes.url_helpers.human_url(conversation.human)
    end

    message_body = case reply_type
    when 'new_customer'
      <<~MESSAGE
      Olá, bem vindo ao myBase, sua carteira de saúde!
      Como posso te ajudar hoje?
    MESSAGE
    when 'existing_customer'
      <<~MESSAGE
      Olá, bem vindo de volta ao myBase!
      O que você gostaria de fazer?
      1. Consultar seus dados de saúde: #{profile_url}
      2. Adicionar novo exame.
      3. Falar com nossa equipe sobre outro assunto.
    MESSAGE
    end

    # Create message record in our database
    message = Message.new(
      conversation: conversation,
      provider_message_id: nil,
      body: message_body,
      direction: :outbound,
      sent_at: Time.current,
      error_code: nil,
      error_message: nil
    )
    if message.save
      # Enqueue the job to process the message asynchronously
      job = TwilioOutboundMessageJob.perform_later(
        conversation.id,
        message.id
      )

      # Log the job ID for tracking
      Rails.logger.info "Enqueued outbound message job with ID: #{job.job_id}"
    end
  end
end

class MessagesChannel < Turbo::StreamsChannel
  def subscribed
    super
    Rails.logger.info "MessagesChannel subscribed to #{stream_name}"
  end

  def unsubscribed
    super
    Rails.logger.info "MessagesChannel unsubscribed from #{stream_name}"
  end
end

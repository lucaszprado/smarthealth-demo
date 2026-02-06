module WhatsappUtils
  def ensure_whatsapp_prefix(phone_number)
    phone_number.start_with?('whatsapp:') ? phone_number : "whatsapp:#{phone_number}"
  end
end

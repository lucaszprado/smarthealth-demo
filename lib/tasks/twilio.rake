namespace :twilio do
  desc "List all conversations in Twilio account"
  task list_conversations: :environment do
    conversations = TwilioConversationApiClient.list_conversations

    puts "\nTwilio Conversations:"
    puts "====================="
    conversations.each do |conv|
      puts "\nSID: #{conv[:sid]}"
      puts "Status: #{conv[:status]}"
      puts "Name: #{conv[:friendly_name]}"
      puts "Customer: #{conv[:customer]}"
      puts "Created: #{conv[:date_created]}"
      puts "Updated: #{conv[:date_updated]}"
      puts "---------------------"
    end
  end

  desc "Get detailed information about a specific conversation"
  task :get_conversation_details, [:sid] => :environment do |t, args|
    unless args[:sid]
      puts "Usage: rake twilio:conversation_details[CONVERSATION_SID]"
      exit
    end

    details = TwilioConversationApiClient.get_conversation_details(args[:sid])

    if details.is_a?(Hash) && details[:error]
      puts "\nError getting conversation details:"
      puts "================================"
      puts "Message: #{details[:error]}"
      if details[:code]
        puts "Error Code: #{details[:code]}"
      end
      if details[:more_info]
        puts "More Info: #{details[:more_info]}"
      end
      exit
    end

    puts "\nConversation Details:"
    puts "===================="
    puts "SID: #{details[:conversation][:sid]}"
    puts "Status: #{details[:conversation][:status]}"
    puts "Name: #{details[:conversation][:friendly_name]}"
    puts "Created: #{details[:conversation][:date_created]}"
    puts "Updated: #{details[:conversation][:date_updated]}"
    puts "URL: #{details[:conversation][:url]}"

    puts "\nParticipants:"
    puts "============"
    details[:participants].each do |p|
      puts "\nSID: #{p[:sid]}"
      puts "Identity: #{p[:identity] || 'None'}"
      puts "Messaging Binding:"
      puts "  Type: #{p[:messaging_binding]['type']}"
      puts "  Address: #{p[:messaging_binding]['address']}"
      puts "  Proxy: #{p[:messaging_binding]['proxy_address']}"
      puts "Created: #{p[:date_created]}"
      puts "Updated: #{p[:date_updated]}"
      puts "-------------------"
    end

    puts "\nLast 20 Messages:"
    puts "================"
    details[:messages].reverse.each do |m|
      puts "\nAuthor: #{m[:author] || 'Unknown'}"
      puts "Body: #{m[:body]}"
      puts "Index: #{m[:index]}"
      puts "Created: #{m[:date_created]}"
      puts "Updated: #{m[:date_updated]}"
      puts "-------------------"
    end
  end

  desc "Update conversation status"
  task :update_status, [:sid, :status] => :environment do |t, args|
    unless args[:sid] && args[:status]
      puts "Usage: rake twilio:update_status[CONVERSATION_SID,STATUS]"
      puts "Status can be: active, closed, or inactive"
      exit
    end

    begin
      result = TwilioConversationApiClient.update_conversation_status(args[:sid], args[:status])
      puts "\nConversation updated:"
      puts "SID: #{result[:sid]}"
      puts "New Status: #{result[:status]}"
      puts "Name: #{result[:friendly_name]}"
      puts "Updated: #{result[:date_updated]}"
    rescue => e
      puts "Error updating conversation: #{e.message}"
    end
  end

  desc "Delete a specific conversation"
  task :delete_conversation, [:sid] => :environment do |t, args|
    unless args[:sid]
      puts "Usage: rake twilio:delete_conversation[CONVERSATION_SID]"
      exit
    end

    if TwilioConversationApiClient.delete_conversation(args[:sid])
      puts "Successfully deleted conversation #{args[:sid]}"
    else
      puts "Failed to delete conversation #{args[:sid]}"
    end
  end

  desc "Delete all conversations (WARNING: This will delete ALL conversations)"
  task delete_all_conversations: :environment do
    print "Are you sure you want to delete ALL conversations? This cannot be undone! (yes/no): "
    response = STDIN.gets.chomp.downcase

    if response == 'yes'
      result = TwilioConversationApiClient.delete_all_conversations
      puts "\nDeletion complete:"
      puts "Deleted #{result[:deleted]} conversations"

      if result[:errors].any?
        puts "\nErrors occurred:"
        result[:errors].each do |error|
          puts "- Conversation #{error[:sid]}: #{error[:error]}"
        end
      end
    else
      puts "Operation cancelled"
    end
  end

  desc "Delete conversations for a specific customer number"
  task :delete_conversations_by_customer, [:number] => :environment do |t, args|
    unless args[:number]
      puts "Usage: rake twilio:delete_by_customer[PHONE_NUMBER]"
      puts "Example: rake twilio:delete_by_customer[+5511982322564]"
      exit
    end

    print "Are you sure you want to delete all conversations for #{args[:number]}? (yes/no): "
    response = STDIN.gets.chomp.downcase

    if response == 'yes'
      result = TwilioConversationApiClient.delete_conversations_by_customer(args[:number])
      puts "\nDeletion complete:"
      puts "Deleted #{result[:deleted]} conversations"

      if result[:errors].any?
        puts "\nErrors occurred:"
        result[:errors].each do |error|
          puts "- Conversation #{error[:sid]}: #{error[:error]}"
        end
      end
    else
      puts "Operation cancelled"
    end
  end

  desc "Search for messages from a specific phone number"
  task :search_messages, [:phone_number] => :environment do |t, args|
    if args[:phone_number].blank?
      puts "Please provide a phone number"
      puts "Usage: rake twilio:search_messages[+1234567890]"
      exit
    end

    # Configure logger to output to both file and STDOUT
    logger = Logger.new(STDOUT)
    # Creates a new logger instance that will output to both the file and STDOUT (terminal)
    logger.level = Logger::INFO
    # Sets the new logger instance to use INFO level of details
    Rails.logger = logger
    # Tells the logger to output to the standard logfiles and STDOUT

    puts "\nSearching for messages from #{args[:phone_number]}..."
    puts "================================================"

    messages = TwilioConversationApiClient.search_messages_by_number(args[:phone_number])

    if messages.empty?
      puts "\nNo messages found for #{args[:phone_number]}"
    else
      puts "\nMessages from #{args[:phone_number]}:"
      puts "=========================\n"

      messages.each do |msg|
        puts "Message SID: #{msg[:sid]}"
        puts "Source: #{msg[:source]}"
        puts "Conversation SID: #{msg[:conversation_sid]}" if msg[:conversation_sid]
        puts "Body: #{msg[:body]}"
        puts "Created: #{msg[:date_created]}"
        puts "Updated: #{msg[:date_updated]}"
        puts "Status: #{msg[:status]}" if msg[:status]
        puts "From: #{msg[:from]}" if msg[:from]
        puts "To: #{msg[:to]}" if msg[:to]
        puts "Author: #{msg[:author]}" if msg[:author]
        puts "----------------------------------------\n"
      end

      puts "\nTotal messages found: #{messages.size}"
    end
  end
end

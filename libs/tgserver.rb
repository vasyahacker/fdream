require 'telegram/bot'

class TelegramServer
  attr_accessor :jb, :game

  TYPE = 'telegram'

  def initialize(jb, token, game)
    @jb = jb

    @dirKey = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(с ю з в), %w(вв вн см)], one_time_keyboard: false)
    @sexKey = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(М Ж)], one_time_keyboard: true)
    @confirm = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(Д Н)], one_time_keyboard: true)

    @regMessage = {}
    @game = game
    @reg = Registration.new(TYPE, game)

    telegram_thread = Thread.new do
      Thread.start(token, game) do |t, g|
        server(t, g)
      end
    end
  end

  def server(token, game)
    Telegram::Bot::Client.run(token) do |bot|

      @bot = bot

      bot.listen do |message|
        if message.text == nil
          next
        end

        sender = "#{message.from.id}@#{TYPE}"
#        print sender + " - #{message.from.first_name} - @#{message.from.username} - message: #{message.text}\n\n"

        unless game.players.key?(sender)
          unless @regMessage[sender]
            @regMessage[sender] = true
            bot.api.send_message(chat_id: message.from.id, text: "Необходимо пройти регистрацию (всего 7 вопросов). Просклоняйте имя вашего персонажа:")
          end

          ret = @reg.RegPlayer(message.from.id, message.text)
          if ret == @reg.questions_messages[6] # sex
            bot.api.send_message(chat_id: message.from.id, text: ret, reply_markup: @sexKey)
            next

          elsif ret == @reg.questions_messages[7] # confirm
            bot.api.send_message(chat_id: message.from.id, text: ret, reply_markup: @confirm)
            next

          elsif ret == @reg.registred_message
            @jb.parse_command(sender, 'start')
            bot.api.send_message(chat_id: message.from.id, text: ret, reply_markup: @dirKey)
            next
          end
          bot.api.send_message(chat_id: message.from.id, text: ret)
          next
        end

        @jb.parse_command(sender, message.text)
      end

    end
  end

  def deliver(sender, txt)
    return false if sender =~ VALID_EMAIL_REGEX || sender =~ /^[0-9]{1,36}@telnet$/
    id = sender.split('@')
    return false unless id[1] == TYPE
    @bot.api.send_message(chat_id: id[0], text: txt, reply_markup: @dirKey)
    return true
  end
end
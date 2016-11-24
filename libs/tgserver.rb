require 'telegram/bot'

class TelegramServer
  attr_accessor :jb, :game

  TYPE = 'telegram'

  def initialize(jb, token, game)
    @jb = jb

    @startKey = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(старт)], one_time_keyboard: false)
    @dirKey = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [
        ['см руки', 'север', 'вверх'],
        %w(запад см восток),
        %w(кто юг вниз),
        %w(инвентарь смс помощь),
        %w(инфо),
        %w(стоп)
    ], one_time_keyboard: false)

    @sexKey = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(М Ж)], one_time_keyboard: true)
    @confirm = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(Да Нет)], one_time_keyboard: true)

    @regMessage = {}
    @game = game
    @reg = Registration.new(TYPE, game)

    telegram_thread = Thread.new do
      Thread.start(token, game) do |t, g|
        begin
          server(t, g)
        rescue => detail
          log "\nОшибка с сервером #{TYPE}: #{$!.to_s}\n"+detail.backtrace.join("\n")
        end
      end
    end
  end

  def server(token, game)
    Telegram::Bot::Client.run(token) do |bot|
      @bot = bot

      bot.listen do |message|
        case message
          when Telegram::Bot::Types::CallbackQuery
            callbackHandler(bot, message)
          when Telegram::Bot::Types::Message
            messageHandler(bot, message)
        end
      end
    end
  end

  def messageHandler(bot, message)
    if message.text.empty?
      return
    end

    sender = Registration.GetLoginOfType(message.from.id, TYPE)

    unless game.players.key?(sender)
      unless @regMessage[sender]
        @regMessage[sender] = true
        bot.api.send_message(chat_id: message.from.id, text: "Необходимо пройти регистрацию (всего 7 вопросов). Просклоняйте имя вашего персонажа:")
      end

      ret = @reg.RegPlayer(message.from.id, message.text)
      if ret == @reg.questions_messages[6] # sex
        bot.api.send_message(chat_id: message.from.id, text: ret, reply_markup: @sexKey)
        return

      elsif ret == @reg.questions_messages[7] # confirm
        bot.api.send_message(chat_id: message.from.id, text: ret, reply_markup: @confirm)
        return

      elsif ret == @reg.registred_message
        @jb.parse_command(sender, 'start')
        bot.api.send_message(chat_id: message.from.id, text: ret, reply_markup: @dirKey)
        return
      end
      bot.api.send_message(chat_id: message.from.id, text: ret)
      return
    end

    begin
      @jb.parse_command(sender, message.text)
    rescue => detail
      log "\nОшибка #{TYPE} при отправке команды: #{message.text} - игроком: #{sender}, боту: #{$!.to_s}\n"+detail.backtrace.join("\n")
    end
  end

  def callbackHandler(bot, message)
    inventoryCallback(bot, message)
    lookAtHereCallback(bot, message)
  end

  def deliver(sender, txt)
    id = sender.split('@')
    return false unless id[1] == TYPE

    begin
      keyboard = @dirKey.clone
      keyboard.keyboard = keyboard.keyboard.clone

      player = @game.players[sender]

      # замена "смотреть на руки" при большой осознаности на "язык к нёбу"
      if player.sensibleness > 99
        keyboard.keyboard[0][0] = 'язык к нёбу'
      end

      # генерация клавиатуры для помощи
      if txt =~ /^Категории команд:\n/i
        keyboard = generateHelpKeyboard(txt)
      end

      # генерация инлайн клавиатуры для инвентаря
      if txt =~ /^У тебя есть:\n/i
        keyboard = generateInventoryKeyboard(txt)
      end

      # генерация инлайн клавиатуры смотреть на "здесь"
      if txt =~ /здесь:\n(.*)выходы/im
        keyboard = generateLookAtHereKeyboard(txt)
      end

      # стартовая клава при выходе и автовыходе
      if txt == @game.descr['autologout'] || txt == @game.TextBuild(@game.descr["wakeup"], player)[0]
        keyboard = @startKey
      end

      # telegram message limit 4096 utf-8 chars
      txt = txt + " \n"
      txt.scan(/.{0,3900}[\.!?\n]+|.{0,4050}[\.!?\n\s]+/m) { |m|
        @bot.api.send_message(chat_id: id[0], text: m, reply_markup: keyboard) unless m.empty?
        sleep(0.1) # add delay for telegram max 30 messages per second
      }
    rescue => detail
      log "\nОшибка #{TYPE} при отправке сообщения: #{txt} - игроку #{sender}: #{$!.to_s}\n"+detail.backtrace.join("\n")
    end

    return true
  end

  def log(mes)
    $stderr.puts "\n[#{Time.now.to_s}]: "+mes
  end

  private

  # look at
  def generateLookAtHereKeyboard(message)
    here = /здесь:\n(.*)\n(Здесь находятся|выходы)/im.match(message).to_a[1].split("\n")

    kb = []
    here.each { |elem|
      name = /^(#{USER_NAME_REGEX})( \(.*\))?$/i.match(elem).to_a[1]
      kb.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: name, callback_data: "LookAtHere-#{name}")) unless name.nil?
    }
    return Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
  end

  def lookAtHereCallback(bot, message)
    lookData = /^LookAtHere-(?<name>#{USER_NAME_REGEX})$/i.match(message.data).to_a
    if !lookData.nil? && !lookData.empty?
      name = lookData[1]
      @jb.parse_command(Registration.GetLoginOfType(message.from.id, TYPE), "посмотреть на #{name}")
    end
  end

  # help
  def generateHelpKeyboard(message)
    help_kb = []
    help_split = message.split(/\n/).drop(2).reverse.drop(2).reverse
    help_split.each do |name|
      help_kb.push(["? #{name}"])
    end

    return Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: help_kb, one_time_keyboard: true)
  end

  # inventory
  INVENTORY_TYPES = [
      ["Осмотреть", "look"],
      ["Использовать", "use"],
      ["Выложить", "miscarry"]
  ]

  def generateInventoryKeyboard(message)
    kb = []

    INVENTORY_TYPES.each { |elem|
      kb.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: elem[0], callback_data: "Inventory-#{elem[1]}"))
    }

    return Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
  end

  def inventoryCallback(bot, message)
    invData = /^Inventory-(?<type>[a-z]*)(-(?<index>[0-9]{1,3}))?$/i.match(message.data).to_a

    if !invData.nil? && !invData.empty?
      kb = []
      addText = ''

      if invData[2].nil?
        line_kb = []
        inv_split = message.message.text.split(/\n/).drop(1)

        for i in 1..inv_split.length
          line_kb.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: "#{i}", callback_data: "Inventory-#{invData[1]}-#{i}"))

          if i % 5 == 0
            kb.push(line_kb.clone)
            line_kb = []
          end
        end
        kb.push(line_kb.clone)

        INVENTORY_TYPES.each { |elem|
          if elem[1] == invData[1]
            addText = "\n\n>> #{elem[0]}:"
          end
        }
      else
        INVENTORY_TYPES.each { |elem|
          if elem[1] == invData[1]
            addText = " #{invData[2]}"
            @jb.parse_command(Registration.GetLoginOfType(message.from.id, TYPE), "#{elem[0]} #{invData[2]}")
          end
        }
      end

      begin
        bot.api.editMessageText(chat_id: message.from.id, message_id: message.message.message_id, text: message.message.text + addText, reply_markup: Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb))
      rescue
        # ignore telegram error
      end
    end
  end
end
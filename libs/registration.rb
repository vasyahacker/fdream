# Author: Vladislav Fursov (ghostrussian@gmail.com)
require 'digest'

class RegTmp
  attr_accessor :qn, :answers

  def initialize
    @qn = 0
    @answers = []
  end
end

class Registration
  attr_accessor :type, :tmpReg, :game

  QUESTIONS_WITH_LOGIN_PASSWORD = [
      'Ваш email',
      'Пароль'
  ]

  QUESTIONS = [
      'Кто? (прим. Вася)',
      'Кого? (Васю)',
      'Кому? (Васе)',
      'Кем? (Васей)',
      'О ком? (Васе)',
      'Чей? (Васи)',
      'Ваш пол? (М)'
  ]

  USER_EXIST = 'Пользователь с таким логином уже существует!'
  REGISTRED_MESSAGE = 'Спасибо за регистрацию, можно начать игру с команды старт'

  def initialize(type, game)
    @game = game
    @type = type
    @tmpReg = {}
  end

  def RegPlayer(id, answer, password = '')
    login = GetLogin(id)

    if @game.players.key?(id) || @game.players.key?(login)
      return USER_EXIST
    end

    @tmpReg[login] = RegTmp.new unless @tmpReg.key?(login)
    n = @tmpReg[login].qn

    @tmpReg[login].answers[n-1] = answer if n > 0

    if n >= QUESTIONS.length
      unless @game.check(login)
        @game.CharCreate(login, @tmpReg[login].answers)
        @game.players[login].pwd = Digest::MD5.hexdigest(password) unless password.empty?
      end

      return REGISTRED_MESSAGE
    end

    n -= 1 if n > 0 && answer == ''

    ask = QUESTIONS[n]

    @tmpReg[login].qn = n + 1
    return ask
  end

  def GetLogin(id)
    return "#{id}@#{@type}"
  end

  def RegPlayerWithLoginAndPassword(tmpId, answer)
    tempLogin = GetLogin(tmpId)

    	[tempLogin] = RegTmp.new unless @tmpReg.key?(tempLogin)
    n = @tmpReg[tempLogin].qn

    ask = nil

    @tmpReg[tempLogin].answers[n-1] = answer if n > 0 && n <= QUESTIONS_WITH_LOGIN_PASSWORD.length

    if n >= QUESTIONS_WITH_LOGIN_PASSWORD.length
      id = @tmpReg[tempLogin].answers[0]
      pass = @tmpReg[tempLogin].answers[1]
      answer = '' if n == QUESTIONS_WITH_LOGIN_PASSWORD.length
      ask = RegPlayer(id, answer, pass)
    else
      n -= 1 if n > 0 && answer == ''
      ask = QUESTIONS_WITH_LOGIN_PASSWORD[n]
    end

    @tmpReg[tempLogin].qn = n + 1
    return ask
  end

  def Reset(id)
    login = GetLogin(id)
    login2 = @tmpReg[login].answers[0] if @tmpReg.key?(login)
    @tmpReg.delete(GetLogin(login2))
    @tmpReg.delete(login)
  end

  # getters
  def questions_with_login_password_messages
    return QUESTIONS_WITH_LOGIN_PASSWORD
  end

  def questions_messages
    return QUESTIONS
  end

  def user_exist_message
    return USER_EXIST
  end

  def registred_message
    return REGISTRED_MESSAGE
  end
end

# -*- coding: utf-8 -*-
require 'socket'
require 'iconv'
class String
  def black;          "\033[30m#{self}\033[0m" end
  def red;            "\033[31m#{self}\033[0m" end
  def green;          "\033[32m#{self}\033[0m" end
  def brown;          "\033[33m#{self}\033[0m" end
  def blue;           "\033[34m#{self}\033[0m" end
  def magenta;        "\033[35m#{self}\033[0m" end
  def cyan;           "\033[36m#{self}\033[0m" end
  def gray;           "\033[37m#{self}\033[0m" end
  def bg_black;       "\033[40m#{self}\0330m"  end
  def bg_red;         "\033[41m#{self}\033[0m" end
  def bg_green;       "\033[42m#{self}\033[0m" end
  def bg_brown;       "\033[43m#{self}\033[0m" end
  def bg_blue;        "\033[44m#{self}\033[0m" end
  def bg_magenta;     "\033[45m#{self}\033[0m" end
  def bg_cyan;        "\033[46m#{self}\033[0m" end
  def bg_gray;        "\033[47m#{self}\033[0m" end
  def bold;           "\033[1m#{self}\033[22m" end
  def reverse_color;  "\033[7m#{self}\033[27m" end
  def pure_string
      loop{ self[/\033\[\d+m/] = "" }
      rescue IndexError
          return self
  end
end
class TelnetUser
  attr_accessor :sock,:enc
  def initialize(s,e)
    @sock = s
    @enc = e
  end
end

class TelServ
  attr_accessor :jb
    
#    TIOCGWINSZ =  0x40087468 
  Encodings = ["KOI8-R","UTF-8","WINDOWS-1251","cp866"]
  def initialize(jb, port=34567, host='0.0.0.0',maxcon=18)
    @logins = {}
    #@encoding = Encodings[1]
    server = TCPServer.new(host,port)
    @jb = jb
    telnet_thread = Thread.new do
      loop do
        Thread.start(server.accept) do |client|
          serv(client)
          client.close
          @logins.delete(client)
        end
      end
    end
  end

  def setcolors(t)
    return nil if t==false
    t=t.gsub("<ч>","\033[30m")
    t=t.gsub("<к>","\033[31m")
    t=t.gsub("<з>","\033[32m")
    t=t.gsub("<кор>","\033[33m")
    t=t.gsub("<с>","\033[34m")
    t=t.gsub("<п>","\033[35m")
    t=t.gsub("<г>","\033[36m")
    t=t.gsub("<g>","\033[37m")
    t=t.gsub("<Ч>","\033[40m")
    t=t.gsub("<К>","\033[41m")
    t=t.gsub("<З>","\033[42m")
    t=t.gsub("<КОР>","\033[43m")
    t=t.gsub("<С>","\033[44m")
    t=t.gsub("<П>","\033[45m")
    t=t.gsub("<Г>","\033[46m")
    t=t.gsub("<G>","\033[47m")
    t.gsub(/<\/[кзсжчпгg]{1}>/i,"\033[0m")
  end

  def q(qu,s,e)
    s.write denc(qu,e)
    a = sock.gets
    a.chomp! unless a.nil?
    a
  end

  def serv(sock)
    logged_in = false
    encoding_selected = false
    sock.write "
 *  .   '   *      #   .    .    *     '  ,\r\n".cyan()+
".    *     .   *   .     .   '    `    *\r\n".cyan()+
" . ".cyan()+"-=<(".blue()+"Forgotten dreaM".bold()+")>=- ".blue()+"'  *\r\n".cyan()+
"  *      .    *    .    *     .    '   .\r\n".cyan()+
"*    .     '      *      .    `    *     '\r\n".cyan()

    login = ""
    begin
      loop do
  #next unless IO.select([sock], nil, nil, 1) 
        until encoding_selected
          sock.write "\r\nSelect encoding: "
          i = 1
          Encodings.each {|e| 
            sock.write "#{i} - #{e}"+((Encodings.size > i) ? ", ": "")
            i += 1
          }
          sock.write ": "
          ei = sock.gets.to_i
          next if ei > Encodings.size or ei <= 0
          encoding = Encodings[ei-1]
          encoding_selected = true
        end
#@encoding = Encodings[1]
        until logged_in
#          sock.write("\r\n"+
 #           denc("Введите new для регистрации или ваш jabber id для входа")+"\r\n")
          sock.write denc("\nВведите ваш Jabber ID: ",encoding)
          login = sock.gets
          login.chomp! unless login.nil?
#TODO регистрация
=begin
          if(login=="new")
            names={}
            
          sock.write("\r\n"+
            denc("Для входа необходимо пройти небольшую процедуру регистрации.")+"\r\n")
          sock.write denc("\nВведите ваш Jabber ID: ",encoding)
            until 
              sock.write("\r\n"+denc("Имя: "))
            end
            $gg.MyNameUnique?(sender, char[1].strip)
            "Кого наказать?"
            "Кому сказать?"
            "С кем встретиться? (без с)"
            "О ком грустит Марио? (без о)"
            "Чьи наркотики?"
            "В туалет с буквой М или Ж ты обычно заходишь?"
          end
=end

          sock.write denc("\nПароль: ",encoding)
          sock.write colorize( 0,"","fg")
          sock.write colorize( 0,"","bg")
          
          password = sock.gets
          password.chomp!  unless password.nil?
          sock.write nocolor ""
          if ( $gg.players.key?(login) and $gg.players[login].pwd == Digest::MD5.hexdigest(password) )
              logged_in = true
              @logins[login] = TelnetUser.new(sock, encoding)
              parse_command(login,"start")
            else
              sleep 2
          end
        end
        message = sock.gets
        message.chomp! unless message.nil?
        if message == "quit"
          log "quit"
          parse_command(login,"stop") 
          sleep 1
          @logins.delete(login)
          break
        end
        #next if sock.eof? 
        #log(message.force_encoding('utf-8'))        
        
        parse_command(login,message) 
      end
      sock.close
    rescue => detail
      log "Ошибка в главном обработчике telnet: #{$!.to_s}"+detail.backtrace.join("\n")
      fclose(login)
    end
  end

  def deliver(login,message)
    begin
      return false if @logins.nil?
      return false unless @logins.key? login
      return true if @logins[login].sock.closed?
      message = message.gsub("\n"," \n\r ")
      message = setcolors(message)
      mes = denc(message,@logins[login].enc)
      @logins[login].sock.write mes+" \n\r"
      true
    rescue => detail
      log "Ошибка в telnet при выводе сообщения: #{$!.to_s}"+detail.backtrace.join("\n")
      fclose(login)
    end
  end
  
  def fclose(login)
    return false if @logins.nil?
    return false unless @logins.key? login
    begin
      $gg.stop(login)
      @logins[login].sock.close unless @logins[login].sock.closed?
      @logins.delete(login)
    rescue => detail
      log "Ошибка принудительного закрытия сокета telnet: #{$!.to_s}"
      log detail.backtrace.join("\n")
    end
  end

  def log(mes)
    $stderr.puts "\n[#{Time.now.to_s}]:"+mes
  end

  def enc(s,encoding)
    s = s.force_encoding(encoding)
    s = s.scan(/[[:print:]]/).join if encoding == 'UTF-8'
    Iconv.iconv('UTF-8', encoding+'//IGNORE', s)[0]
  end
  
  def denc(s,encoding)
    s = s.force_encoding(encoding)
    Iconv.iconv(encoding+'//IGNORE', 'UTF-8', s)[0]
  end

  def parse_command(sender,message)
    #parse_thread = Thread.new do
    return if message.nil?
    return if sender.nil?
    return unless @logins.key? sender
      begin
        cmd = enc( message,@logins[sender].enc )
        cmd = CGI::unescapeHTML(cmd)
        @jb.parse_command(sender, cmd)
      rescue => detail
        log"\nОшибка telnet при отправке команды боту: #{$!.to_s}\n"+detail.backtrace.join("\n")
      end
    #end
    #parse_thread.join
  end
  
  ColorMode = {'fg' => '38', 'bg' => '48'}
  def colorize(color, text, mode)
    "\x1b[#{ColorMode[mode]};5;#{color}m#{text}"
  end
  
  def nocolor(text)
    "\x1b[0m#{text}"
  end
    
end

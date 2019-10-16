require 'sinatra'   # gem 'sinatra'
require 'line/bot'  # gem 'line-bot-api'

def client
  @client ||= Line::Bot::Client.new { |config|
	# 你自己LINE的 channel_secret & channel_token
    config.channel_secret = 'your_channel_secret'
    config.channel_token = 'your_channel_token'
  }
end

post '/callback' do
  body = request.body.read

  signature = request.env['HTTP_X_LINE_SIGNATURE']
  unless client.validate_signature(body, signature)
    halt 400, {'Content-Type' => 'text/plain'}, 'Bad Request'
  end

  events = client.parse_events_from(body)

  events.each do |event|
    case event
    when Line::Bot::Event::Message
      case event.type
      
	  # line-bot-ruby-sdk 範例的一部分
	  # 傳什麼字就回你什麼字
	  when Line::Bot::Event::MessageType::Text
        message = {
          type: 'text',
          text: event.message['text']
        }
        client.reply_message(event['replyToken'], message)
		
	  when Line::Bot::Event::MessageType::Image
        
		# 從LINE 取得response
		response = client.get_message_content(event.message['id'])
	
		case response
			when Net::HTTPSuccess then
				# 路徑一定要在public內 (所以建議直接clone下來)
				# 後面檔案名自訂，如果沒有這個檔案會新建立
				# 否則複寫上去
				File.open("public/lineimg.jpg", "wb") do |f|
					f.write(response.body)
				end
			else
			  p "#{response.code} #{response.body}"
		end
		
		message = {
          type: 'text',
          text: '收到圖片了'
        }
		
		client.reply_message(event['replyToken'], message)		
      end
    end
  end

  "OK"
end

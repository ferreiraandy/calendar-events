require 'sinatra'
require 'googleauth'
require 'googleauth/stores/redis_token_store'
require 'google/apis/drive_v3'
require 'google/apis/calendar_v3'
require 'google-id-token'
require 'dotenv'

LOGIN_URL = '/'.freeze

configure do
  Dotenv.load

  Google::Apis::ClientOptions.default.application_name = 'Ruby client samples'
  Google::Apis::ClientOptions.default.application_version = '0.9'
  Google::Apis::RequestOptions.default.retries = 3

  enable :sessions
  set :show_exceptions, false
  set :client_id, Google::Auth::ClientId.new(ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'])
  set :token_store, Google::Auth::Stores::RedisTokenStore.new(redis: Redis.new)
end

helpers do
  def credentials_for(scope)
    authorizer = Google::Auth::WebUserAuthorizer.new(settings.client_id, scope, settings.token_store)
    user_id = session[:user_id]
    redirect LOGIN_URL if user_id.nil?
    credentials = authorizer.get_credentials(user_id, request)

    redirect authorizer.get_authorization_url(login_hint: user_id, request: request) unless credentials

    credentials
  end

  def resize(url, width)
    url.sub(/s220/, sprintf('s%d', width))
  end

  def event_date(date)
    Google::Apis::CalendarV3::EventDateTime.new(
      date_time: date,
      time_zone: 'America/Sao_Paulo'
    )
  end

  def attendee(customers)
    customers.map do |customer|
      Google::Apis::CalendarV3::EventAttendee.new(email: customer)
    end
  end

  def reminder
    Google::Apis::CalendarV3::Event::Reminders.new(
      use_default: false,
      overrides: [
        Google::Apis::CalendarV3::EventReminder.new(reminder_method: 'email', minutes: 24 * 60),
        Google::Apis::CalendarV3::EventReminder.new(reminder_method: 'popup', minutes: 10)
      ]
    )
  end

  def message_description
    '''
      Oi, O próximo pedido da sua assinatura está prestes a ser fechado.
      Essa é a hora ideal para:
      - Revisar os produtos
      - Revisar informações de pagamento
      - Checar se o endereço de entrega está correto

      Também é uma ótima oportunidade para aproveitar essa entrega e incluir produtos que deseja receber apenas uma vez (como brinquedos, acessórios, petiscos...).
      Para isso, basta clicar aqui http://petlove.com.br/my_pet_club e adicioná-los na sua assinatura, além de marcar a opção de receber apenas na próxima entrega.

      Caso tenha qualquer dúvida, tanto sobre a sua assinatura quanto indicação de produtos, responda essa mensagem no whats app, (clicando aqui) para que um dos nossos especialistas possa te ajudar!

      Abraços, Matilha Petlove
    '''
  end

  def message
    Google::Apis::CalendarV3::Event.new(
      summary: 'Sua assinatura estã fechando',
      location: 'Av. Dr. Cardoso de Melo, 1155 - Vila Olimpia, São Paulo - SP, 04548-004',
      description: message_description,
      start: event_date('2021-07-23T09:00:00-03:00'),
      end: event_date('2021-07-23T17:00:00-03:00'),
      recurrence: ['RRULE:FREQ=DAILY;COUNT=2'],
      attendees: attendee(['andyferreira92@gmail.com', 'anderson.ferreira@petlove.com']),
      reminders: reminder
    )
  end

  def event_creator(service)
    result = service.insert_event('primary', message)
    puts "Event created: #{result.html_link}"
  end
end

get('/') do
  @client_id = settings.client_id.id
  erb :home
end

post('/signin') do
  audience = settings.client_id.id
  validator = GoogleIDToken::Validator.new
  claim = validator.check(params['id_token'], audience, audience)

  if claim
    session[:user_id] = claim['sub']
    session[:user_email] = claim['email']
    200
  else
    logger.info('No valid identity token present')
    401
  end
end

get('/calendar') do
  calendar = Google::Apis::CalendarV3::CalendarService.new
  calendar.authorization = credentials_for(Google::Apis::CalendarV3::AUTH_CALENDAR)

  @result = calendar.list_events(
    'primary',
    max_results: 10,
    single_events: true,
    order_by: 'startTime',
    time_min: Time.now.iso8601
  )

  event_creator(calendar)

  erb :calendar
end

get('/oauth2callback') do
  target_url = Google::Auth::WebUserAuthorizer.handle_auth_callback_deferred(request)
  redirect target_url
end

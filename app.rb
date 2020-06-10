# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"                                                                 #
require "geocoder"                                                                    #
require "bcrypt"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

rides_table = DB.from(:rides)
rsvps_table = DB.from(:rsvps)
users_table = DB.from(:users)

before do
    # SELECT * FROM users WHERE id = session[:user_id]
    @current_user = users_table.where(:id => session[:user_id]).to_a[0]
    puts @current_user.inspect
end

# Home page (all events)
get "/" do
    # before stuff runs
    @rides = rides_table.all
    view "rides"
end

# Show a single event
get "/rides/:id" do
    @users_table = users_table
    # SELECT * FROM rides WHERE id=:id
    @ride = rides_table.where(:id => params["id"]).to_a[0]
    # SELECT * FROM rsvps WHERE ride_id=:id
    @rsvps = rsvps_table.where(:ride_id => params["id"]).to_a
    # SELECT COUNT(*) FROM rsvps WHERE ride_id=:id AND going=1
    @count = rsvps_table.where(:ride_id => params["id"], :going => true).count

    results = Geocoder.search(@ride[:address])
    @lat_long = results.first.coordinates.join(",")

    view "ride"
end

# Form to create a new RSVP
get "/rides/:id/rsvps/new" do

    @ride = rides_table.where(:id => params["id"]).to_a[0]
    view "new_rsvp"
end

# Receiving end of new RSVP form
post "/rides/:id/rsvps/create" do
    if @current_user
    rsvps_table.insert(:ride_id => params["id"],
                       :going => params["going"],
                       :user_id => @current_user[:id],
                      :comments => params["comments"],
                      :anonymous => params["anon"])
    @ride = rides_table.where(:id => params["id"]).to_a[0]
    view "create_rsvp"
    else
        view "no_user"
    end
end

# Form to create a new user
get "/users/new" do
    view "new_user"
end

# Receiving end of new user form
post "/users/create" do
    puts params.inspect
    users_table.insert(:name => params["name"],
                       :email => params["email"],
                       :password => BCrypt::Password.create(params["password"]))
    view "create_user"
end

# Form to login
get "/logins/new" do
    view "new_login"
end

# Receiving end of login form
post "/logins/create" do
    puts params
    email_entered = params["email"]
    password_entered = params["password"]
    # SELECT * FROM users WHERE email = email_entered
    user = users_table.where(:email => email_entered).to_a[0]
    if user
        puts user.inspect
        # test the password against the one in the users table
        if BCrypt::Password.new(user[:password]) == password_entered
            session[:user_id] = user[:id]
            view "create_login"
        else
            view "create_login_failed"
        end
    else 
        view "create_login_failed"
    end
end

# Logout
get "/logout" do
    session[:user_id] = nil
    view "logout"
end

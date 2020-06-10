# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model
DB.create_table! :rides do
  primary_key :id
  String :title
  String :description, text: true
  String :date
  String :location
  String :address
end
DB.create_table! :rsvps do
  primary_key :id
  foreign_key :event_id
  Boolean :going
  String :name
  String :email
  String :comments, text: true
end

# Insert initial (seed) data
rides_table = DB.from(:rides)

rides_table.insert(title: "Bike with Bunkie", 
                    description: "Weekly ride, leaves promptly at 6:30p. Multiple group speeds available (12-14, 14-16, 18-20mph ride average). Road bike, helmet, and lights required.",
                    date: "June 9",
                    location: "Bike shop on Santa Monica", 
                    address: "6940 N Santa Monica Blvd, Milwaukee, WI 53217")

rides_table.insert(title: "G4B Wednesdays", 
                    description: "Gears for Beers Wednesday night rides. Ride bikes, drink some beer. Leaves at 6:30p.",
                    date: "June 10",
                    location: "Loveland Gazebo",
                    address: "126 Karl Brown Way, Loveland, OH 45140")

rides_table.insert(title: "Kellogg Kasual", 
                    description: "De-stress with a casual roll down the lakefront path. Bikes not provided.",
                    date: "June 19",
                    location: "GLUB",
                    address: "2211 Campus Dr, Evanston, IL 60208")

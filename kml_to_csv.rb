require 'rubygems'
require 'nokogiri'
require 'csv'

doc = Nokogiri::XML(open('overpass_export.kml'))

stones = []

doc.css("Placemark").each do |placemark|
  name = placemark.css('name').text
  coordinates = placemark.css('coordinates').text.split(",").reverse
  address = placemark.css('Data[name="memorial:addr"]').text
  stones << { name: name, address: address, coordinates: coordinates }
end

stones.sort_by!{|a| a[:name] }


string =  CSV.generate do |csv|
  stones.each do |stone|
    csv << stone[:coordinates] + [stone[:address], stone[:name], ""]
  end
end

puts string
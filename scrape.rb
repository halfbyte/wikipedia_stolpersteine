#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'csv'

overview_page = Nokogiri::HTML(open('http://de.wikipedia.org/wiki/Kategorie:Liste_%28Stolpersteine_in_Hamburg%29'))

links = []
overview_page.css('a').each do |link|
  href = link['href']
  next if href.nil?
  match = href.match(/\/wiki\/(Liste_der_Stolpersteine_in_Hamburg\-.*)$/)
  if match
    links << match[1]
  end
end

def last_text_node(node)
  node.children.select {|c|
    c.node_type == Nokogiri::XML::Node::TEXT_NODE
  }.map(&:text).join(" ").strip
end

def without_sort_key(node)
  node.children.reject {|c|
    c['class'] && c['class'].include?('sortkey')
  }.map(&:text).join(" ").strip

end

stones = []


links.each do |link|
  foo = open("http://de.wikipedia.org/wiki/#{link}")

  doc = Nokogiri::HTML(foo)


  title = doc.css('#firstHeading').first.text

  match = title.match(/Liste der Stolpersteine in Hamburg-(.*)$/)
  stadtteil = ""
  name = ""
  address = ""
  coodinates = [nil,nil]
  if match
    stadtteil = match[1]
  end

  doc.css('table tr').each do |tr|
    coordinates = [nil,nil]
    next if tr.css('th').size > 0
    if tr.css('td')[0]
      address_field = tr.css('td')[0]
      link = address_field.css('[title="Koordinate"] a[href]')[0]
      if link
        match = link['href'].match(/params=([\d\.]+)_N_([\d\.]+)_E/)
        if match
          coordinates = [match[1], match[2]]
        else
          coordinates = [nil,nil]
        end
      end

      address = last_text_node(address_field)
    end
    if tr.css('td')[1]
      name = without_sort_key(tr.css('td')[1]).gsub(/\n/, " ")
    end
    stones << { name: name, address: address, coordinates: coordinates }
  end
end

stones.sort_by!{|a| a[:name] }




string =  CSV.generate do |csv|
  stones.each do |stone|
    if stone[:coordinates].nil?
      puts stone.inspect
    end
    csv << stone[:coordinates] + [stone[:address], stone[:name], ""]
  end
end

puts string
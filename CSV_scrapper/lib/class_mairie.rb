require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'csv'

class Mairie
  @@url = "http://annuaire-des-mairies.com" # Le lien de base

  # recuperer les href pour aller a chaque page du ville de Val d'oise
  def initialize
    @doc = Nokogiri::HTML(URI.open("http://annuaire-des-mairies.com/val-d-oise.html"))
    @href_arr = @doc.css('.lientxt[href]').map do |link|
      link['href'].gsub(/^./, '')
    end
  end
  
  # reconstituer le lien complet pour acceder a chaque page
  def full_link
    @href_arr.map do |link|
      @@url + link
    end
  end

  # recuperer les emails de chaque page
  def get_townhall_email(townhall_url)
    stream = URI.open(townhall_url)
    doc = Nokogiri::HTML(stream.read)
    a = doc.css('tbody tr')
    arr = a[3].text.split
    return arr[2]
  end

  # recuperer les titres de chaques page
  def get_city_names(url)
    doc = Nokogiri::HTML(URI.open(url))
    href = doc.css('.col-lg-offset-1')
    text = href.text.split
    return text[0]
  end

  # reconstitution du resultat
  def perform
    result = []
    full_link.each do |element|
      result << {get_city_names(element) => get_townhall_email(element)}
      puts result
      end

      # pour demander si l'utilisateur veut modifier le fichier cvs
      puts '_________________________________________________________________'
      puts "Veux tu modifier le fichier CSV? (oui ou non)"
      print '>'
      confirm = gets.chomp
      if confirm == 'oui'
        # Ouverture et ecriture du fichier csv
        result = result.map{ |element| element.map{|k, v| [k, v]}}
        result = result.map { |data| data.join(",") }.join("\n")
        File.open("./db/emails.csv", 'w') do |file|
        file.write(result)
        end
        puts "CSV reecrit avec succes!"
      else
        puts "CSV reste intacte"
      end
  end
end

email = Mairie.new
email.perform

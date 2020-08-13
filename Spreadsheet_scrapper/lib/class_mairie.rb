require 'rubygems'
require 'nokogiri'
require 'open-uri'
require "google_drive"


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

      # confirmation pour modifier le spreadsheet
      puts '_________________________________________________________________'
      puts "Veux tu modifier le fichier spreadsheet? (oui ou non)"
      print '>'
      confirm = gets.chomp

      if confirm == 'oui'
        # Accession a google sheet
        session = GoogleDrive::Session.from_service_account_key("./db/config.json")
        ws = session.spreadsheet_by_title("spreadsheetRuby").worksheets[0]
        k = 2
        ws[1, 1] = "Ville"
        ws[1, 2] = "Email"

        result[0..90].each do |element| # (0..90) a cause du restriction de google (requests per 100 seconds)
            element.each do |key, value|
              ws[k, 1] = key
              ws[k, 2] = value
              ws.save 
              k += 1
          end
        end
        puts "Spreadsheed reecrit avec succes!"

      else
        puts "Spreadsheet reste intacte"
      end
  end
end

email = Mairie.new
email.perform

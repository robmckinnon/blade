require 'date'

module Ppcs; end

class Ppcs::LabourScrape

  def perform result
    scrape_new_ppcs result
    scrape_restanding_mps result
    result
  end

  private

    def scrape_new_ppcs result
      ppc_links('ppc') { |link| scrape_new_ppc link, result }
    end

    def scrape_restanding_mps result
      ppc_links('mp') { |link| scrape_restanding_mp link, result }
    end

    def scrape_new_ppc ppc_link, result
      resource = scrape_resource(ppc_link['href'])
      result.add resource
    end

    def scrape_restanding_mp ppc_link, result
      resource = scrape_resource(ppc_link['href'])
      doc = resource.hpricot_doc
      div = doc.at('div.main_news_content')
      if div
        parts = div.at('td[2]').inner_html
        text = parts.to_s.sub('PPC for Orkney<br />PPC for Shetland','PPC for Orkney and Shetland')
        if ppc_for = text[/PPC for ([^<]+)</,1]
          result.add resource
        end
      end
    end

    def scrape_resource uri
      uri = "http://www.labour.org.uk#{uri}"
      puts "downloading #{uri}"
      WebResource.scrape(uri) do |text|
        text.gsub!(/^.+latest_link_0(1|2).+$/,'') # remove latest news
        text.gsub!(/^.+latest_text.+$/,'')
      end
    end
    
    def ppc_links type, &block
      ('A'..'Z').each do |index|
        get_ppc_links(index, type).each do |ppc_link|
          yield ppc_link
        end
      end
    end
    
    def get_ppc_links index, type
      puts index
      resource = scrape_resource("/#{type}/#{index}/")
      resource.links.select {|a| a['href'][/#{type}\/[a-z][a-z]/] && !a['href'][/constituencies/] && !(a.inner_text.strip.size == 0) }
    end
end

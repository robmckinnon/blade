require 'date'

module Ppcs; end

class Ppcs::ConservativeScrape

  def perform result
    no_constituency = []
    scrape_ppcs result, no_constituency
    unless no_constituency.empty?
      puts "No constituency found for:"
      no_constituency.each { |uri| puts uri }
    end
    result
  end

  private

    def scrape_ppcs result, no_constituency
      ppc_links { |link| scrape_ppc link, result, no_constituency }
    end

    def scrape_ppc ppc_link, result, no_constituency
      resource = scrape_resource(ppc_link['href'])
      doc = resource.hpricot_doc
      div = doc.at('div.main-txt')
      details = div.at('h2').inner_text
      if details.include?('Prospective Parliamentary Candidate for ')
        result.add resource
      else
        no_constituency << ppc_link
      end
    end

    def scrape_resource uri
      uri = "http://www.conservatives.com#{uri}"
      puts "downloading #{uri}"
      WebResource.scrape(uri) do |text|
        text.gsub!(/^.+__VIEWSTATE.+$/,'') # remove variable content
        text.gsub!(/^.+__EVENTVALIDATION.+$/,'')
        text.gsub!(/^.+server:live.+$/,'')
        text.gsub!("</td><td>","</td>\n<td>")
        text.gsub!("</tr><tr>","</tr>\n<tr>")
      end
    end
    
    def ppc_links &block
      path = "/People/Prospective_Parliamentary_Candidates.aspx?&by=All"
      resource = scrape_resource(path)
      links = resource.links
      links = links.select {|a| a['href'] && a['href'][/People\/(Prospective_Parliamentary_Candidates|Members_of_Parliament)\//] && !a.inner_text.blank? }
      links.each {|link| yield link}
    end
end

require 'date'

module Ppcs; end

  class Ppcs::LibdemScrape

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
      resource = scrape_resource(ppc_link)
      doc = resource.hpricot_doc
      heading = doc.at('#divHeading/h1').inner_text
      name = heading.split('–').first.strip
      details = doc.at('#divIntroduction/h2').inner_html.gsub('<br>',' ').gsub(/<[^>]+>/,'').gsub(/<\/[^>]+>/,'')
  
      constituency = nil
      if details.include?('Liberal Democrat candidate for ')
        constituency = details.split('Liberal Democrat candidate for ').last.strip
        if name == 'Peter Fisher' && constituency == 'Ribble Valley'
          constituency = 'South Ribble'
        end
      elsif details.include?('PPC for ')
        constituency = details.split('PPC for ').last.strip
      elsif details.include?('MP for ')
        constituency = details.split('MP for ').last.strip unless name[/Barrett/i]
      elsif name[/morton/i]
        constituency = 'Pudsey'
      end
      
      if constituency
        constituency = constituency.downcase.gsub('&','and').gsub(' ','_')      
        result.add resource
      else
        no_constituency << ppc_link
      end
    end

    def scrape_resource uri
      uri = "http://libdems.org.uk/#{uri}"
      puts "downloading #{uri}"
      WebResource.scrape(uri) do |text|
        # text.gsub!(/^.+__VIEWSTATE.+$/,'') # remove variable content
        # text.gsub!(/^.+__EVENTVALIDATION.+$/,'')
        # text.gsub!(/^.+server:live.+$/,'')
        # text.gsub!("</td><td>","</td>\n<td>")
        # text.gsub!("</tr><tr>","</tr>\n<tr>")
      end
    end
    
    def ppc_links &block
      path = "parliamentary_candidates.aspx?show=Candidates&pgNo=0"
      resource = scrape_resource(path)
      doc = resource.hpricot_doc
      pages = (doc/'option').collect{|x| x['value']}.compact.select{|x| x[/parliamentary_candidates\.aspx\?show/] }
      
      pages.each do |page|
        puts page
        resource = scrape_resource(page)
        links = resource.links.select{|a| a['href'] && a['href'][/parliamentary_candidates_detail\.aspx\?name/] }
        links = links.select{|a| !a.inner_text.blank? && a.inner_text != 'Image'}.collect{|a| a['href']}.uniq
        links.each {|link| yield link}
      end
    end
end

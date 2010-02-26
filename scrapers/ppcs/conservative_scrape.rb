require File.expand_path(File.dirname(__FILE__) + '/ppc_scraper_base')

class Ppcs::ConservativeScrape

  include Ppcs::ScraperBase

  def uri path
    uri = "http://www.conservatives.com#{path}"
  end
  
  def remove_variable_content text
    text.gsub!(/^.+__VIEWSTATE.+$/,'') # remove variable content
    text.gsub!(/^.+__EVENTVALIDATION.+$/,'')
    text.gsub!(/^.+server:live.+$/,'')
    text.gsub!("</td><td>","</td>\n<td>")
    text.gsub!("</tr><tr>","</tr>\n<tr>")
  end

  def scrape_ppc uri_path
    resource = scrape_resource(uri_path)
    doc = resource.hpricot_doc
    div = doc.at('div.main-txt')
    details = div.at('h2').inner_text
    if details.include?('Prospective Parliamentary Candidate for ')
      resource
    else
      nil
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

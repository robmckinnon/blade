require File.expand_path(File.dirname(__FILE__) + '/ppc_scraper_base')

class Ppcs::LabourScrape

  include Ppcs::ScraperBase

  def uri path
    uri = "http://www.labour.org.uk#{path}"
  end

  def remove_variable_content text
    text.gsub!(/^.+latest_link_0(1|2).+$/,'') # remove latest news
    text.gsub!(/^.+latest_text.+$/,'')
  end

  def scrape_ppcs
    scrape_new_ppcs
    scrape_restanding_mps
  end
  
  def scrape_new_ppcs
    ppc_links('ppc') { |link| scrape_new_ppc link['href'] }
  end

  def scrape_restanding_mps
    ppc_links('mp') { |link| scrape_restanding_mp link['href'] }
  end

  def scrape_new_ppc uri_path
    resource = scrape_resource(uri_path)
    @result.add resource
  end

  def scrape_restanding_mp uri_path
    resource = scrape_resource(uri_path)
    doc = resource.hpricot_doc
    div = doc.at('div.main_news_content')
    if div
      parts = div.at('td[2]').inner_html
      text = parts.to_s.sub('PPC for Orkney<br />PPC for Shetland','PPC for Orkney and Shetland')
      if ppc_for = text[/PPC for ([^<]+)</,1]
        @result.add resource
      end
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

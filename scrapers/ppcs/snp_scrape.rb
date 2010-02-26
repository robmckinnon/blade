require File.expand_path(File.dirname(__FILE__) + '/ppc_scraper_base')

class Ppcs::SnpScrape

  include Ppcs::ScraperBase

  def uri path
    uri = "http://www.snp.org#{path}"
  end

  def remove_variable_content text
  end

  def scrape_ppc uri_path
    scrape_resource(uri_path)
  end

  def ppc_links &block
    path = "/people/candidates/Westminster"
    resource = scrape_resource(path)
    links = resource.links
    links = links.select {|a| a['href'] && a['href'][/\/people\//] && !a['href'][/(candidates|holyrood|westminster|europe|councillors)/] && !a.inner_text.blank? }
    links.each {|link| yield link}
  end
end

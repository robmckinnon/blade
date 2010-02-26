require File.expand_path(File.dirname(__FILE__) + '/ppc_scraper_base')

class Ppcs::LibdemScrape

  include Ppcs::ScraperBase

  def uri path
    uri = "http://libdems.org.uk/#{uri}"
  end

  def remove_variable_content text
  end

  def scrape_ppc ppc_link
    resource = scrape_resource(uri_path)
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
      resource
    else
      nil
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

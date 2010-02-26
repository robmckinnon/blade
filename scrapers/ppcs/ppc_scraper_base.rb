module Ppcs; end
  
module Ppcs::ScraperBase

  def perform result
    @result = result
    @no_constituency = []
    scrape_ppcs
    unless @no_constituency.empty?
      puts "No constituency found for:"
      @no_constituency.each { |uri| puts uri }
    end
    @result
  end  

  def scrape_ppcs
    ppc_links do |link|
      resource = scrape_ppc(link['href'])
      if resource
        @result.add resource
      else
        @no_constituency << link
      end
    end
  end

  def scrape_resource path
    puts "downloading #{uri(path)}"
    WebResource.scrape(uri(path), @result.commit_result) do |text|
      remove_variable_content text
    end
  end

end

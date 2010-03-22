# require File.expand_path(File.dirname(__FILE__) + '/ppc_scraper_base')

module Appc; end

class Appc::RegisterScrape

  def perform result
    [
    'http://www.appc.org.uk/appc/filemanager/root/site_assets/pdfs/appc_register_entry_for_1_december_2009_to_28_february_2010.pdf',
    ].each do |uri|
        WebResource.scrape_and_add(uri, result)
    end
  end
end

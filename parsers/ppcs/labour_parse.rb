require File.expand_path(File.dirname(__FILE__) + '/ppc_parser_base')

class Ppcs::LabourParse
  
  include Ppcs::ParserBase

  def preprocess_text text
    text.gsub!(/<!-- BLOCK: (\w+) -->/, '<div class="attribute" id="\1">')
    text.gsub!(/<!-- ENDBLOCK: (\w+) -->/, '</div>')
  end

  def populate_ppc doc, ppc, file
    div = doc.at('div[@class="main_news_content"]')
    if div
      ppc.name = div.at('h1').inner_text.sub(/^Councillor /,'')

      parts = div.at('td[2]').inner_html
      text = parts.to_s.sub('PPC for Orkney<br />PPC for Shetland', 'PPC for Orkney and Shetland')
      ppc_for = text[/PPC for ([^<]+)</,1]

      ppc.constituency = ppc_for
      ppc.mp_for = get_mp_for(text, file)
      set_image ppc, doc.at('div[@class="main_news_content_text"]').at('td/img'), "http://www.labour.org.uk/"

      add_attributes doc, ppc unless (ppc.respond_to?(:mp_for) && ppc.mp_for)

      ppc.twfy_party = 'Labour'
      ppc
    else
      nil
    end
  end

  def add_attributes doc, ppc
    details = (doc/'div[@class="attribute"]')
    details.each do |detail|
      attribute = detail['id']
      unless attribute == 'BlockTitle'
        value = if attribute == 'Biography'
                  detail.inner_html.strip.gsub("\r",'').gsub("\n",'\n')
                else
                  detail.inner_text.strip.split(':').last.strip.gsub("\r",'').gsub("\n",'\n')
                end
        ppc.morph(attribute.gsub(/([A-Z])/,' \1'), value)
      end
    end
  end

  def get_mp_for text, file
    if file[%r|/mps/|] && (mp_for = text[/MP for ([^<]+)</,1])
      mp_for.strip.gsub(' & ',' and ').gsub(' &amp; ',' and ')
    else
      nil
    end
  end

  def map_attributes
    {
    :email => :email_address,
    :website => :website_address,
    :address => :postal_address
    }
  end

end

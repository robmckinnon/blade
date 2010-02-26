require File.expand_path(File.dirname(__FILE__) + '/ppc_parser_base')

class Ppcs::ConservativeParse

  include Ppcs::ParserBase

  def populate_ppc doc, ppc, file
    div = doc.at('div[@class="main-txt"]')
    ppc.name = div.at('h1').inner_text
    text = div.at('h2').inner_text
    details = div.at('h2').inner_html
    ppc.constituency = details[/Prospective Parliamentary Candidate for ([^<]+)</,1].strip.gsub(' &amp; ',' and ')
    ppc.mp_for = get_mp_for(details, file)

    add_attributes doc, ppc, div
    div = doc.at('div[@class="personBody"]')
    img = div.at('div[@class="personImage"]')
    if img
      set_image ppc, img.at('img'), "http://www.conservatives.com"
    end
    ppc.bio = div.inner_html.sub(img.to_s,'').strip.gsub("\r",'').gsub("\n",'\n')

    ppc.twfy_party = 'Conservative'
    ppc
  end

  def add_attributes doc, ppc, div
    details = div.at('p').inner_text.
        sub('House of Commons, London, SW1A 0AA. ','').
        sub('Constituency: ','Office: ').
        gsub("\r",'').squeeze(" ").squeeze("\t").split("/").map(&:strip)
    details = details.collect do |x|
      if x.split("Email:").size == 2
        values = x.split("Email:")
        [values[0], "Email: #{values[1]}"]
      elsif x.split("Web:").size == 2
        values = x.split("Web:")
        [values[0], "Web: #{values[1]}"]
      else
        x
      end
    end.flatten

    details.each do |detail|
      if detail[/:/]
        values = detail.split(':')
        ppc.morph(values[0].strip, values[1].strip)
      else
        ppc.office = detail.split(',').map{|x| x.gsub("\r",'').split("\n")}.flatten.map(&:strip).select{|x| !x.blank?}.join('\n')
      end
    end
  end

  def get_mp_for text, file
    if file[%r|/mps/|] && (mp_for = text[/Member of Parliament for ([^<]+)</,1])
      mp_for.strip.gsub(' & ',' and ').gsub(' &amp; ',' and ')
    else
      nil
    end
  end

  def map_attributes
    {
    :website => :web,
    :telephone => :tel,
    :address => :office,
    :biography => :bio
    }
  end

end

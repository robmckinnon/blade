require File.expand_path(File.dirname(__FILE__) + '/ppc_parser_base')

class Ppcs::SnpParse
  
  include Ppcs::ParserBase

  def populate_ppc doc, ppc, file
    header = doc.at('td[@class="people_info"]/h3')
    if header
      parts = header.inner_text.split(': ')
      ppc.name = parts[1]
      ppc.constituency = parts[0]
      set_image ppc, doc.at('img[@class="image image-thumbnail "]'), ""
      
      bio = (doc/'h2.section/..')
      if bio.empty?
        # ignore
      elsif bio.size == 1
        ppc.biography = bio.first.inner_html.sub('<h2 class="section">Biography</h2>','').strip.gsub("\r",'').gsub("\n",'\n')
      else
        puts "too many bios: #{bio.inspect}"
      end

      ppc.twfy_party = 'Scottish National Party'
      ppc
    else
      nil
    end
  end

  def map_attributes
    {
    }
  end

end

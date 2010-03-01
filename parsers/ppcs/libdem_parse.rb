# encoding:utf-8

require File.expand_path(File.dirname(__FILE__) + '/ppc_parser_base')

class Ppcs::LibdemParse
  
  include Ppcs::ParserBase

  def populate_ppc doc, ppc, file
    heading = doc.at('#divHeading/h1').inner_text
    name = heading.split('–').first.strip
    details_html = doc.at('#divIntroduction/h2').inner_html
    details = details_html.gsub('<br>',' ').gsub(/<[^>]+>/,'').gsub(/<\/[^>]+>/,'')

    if img = doc.at('#divIntroduction/a/img')
      ppc.image = img['src']
    end

    ppc.mp_for = ''
    ppc.name = name
    ppc.mp_for = get_mp_for(details_html)
    ppc.constituency = get_constituency(details, ppc).gsub('&',' and ').
      sub('Lewishan Deptford','Lewisham, Deptford').
      sub('Morecombe ','Morecambe ').
      sub('Ogwr','Ogmore').
      sub(/Dover\sand\sDeal/,'Dover').
      sub('Plymouth Moorview','Plymouth Moor View').
      sub(/^Hull East$/,'Kingston upon Hull East')

    if ppc.constituency[/Whitstable/]
      ppc.constituency = 'Canterbury'
    elsif ppc.constituency[/\sDeal/]
      ppc.constituency = 'Dover'
    elsif ppc.constituency[/\sW\s/]
      ppc.constituency = 'Carmarthen West and South Pembrokeshire'
    elsif ppc.constituency[/Banff,/]
      ppc.constituency = 'Banff and Buchan'
    end

    ppc.bio = doc.at('#divBiography').inner_html.gsub("\r",'').strip.gsub("\n",'\n').gsub(/\\n\s+</,"\\n<")
    add_attributes doc, ppc

    ppc.twfy_party = 'Liberal Democrat'
    ppc
  end

  def add_attributes doc, ppc
    attribute = nil
    value = nil

    doc.at('#divIndividualContactInfo').children.each do |node|
      text = node.inner_text.strip
      if text && text[/(.+):$/]
        if attribute && value
          ppc.morph(attribute, value)
        end
        attribute = $1
        value = nil
      elsif attribute
        if node.name == 'ul'
          value = []
          node.children.each do |node|
            value << node.inner_text.strip unless node.inner_text.blank?
          end
        else
          value = text.strip unless text.strip.blank?
        end
      end
    end
    if attribute && value
      ppc.morph(attribute, value.is_a?(Array) ? value.compact.join('\n') : value)
    end
  end

  def get_mp_for text
    if mp_for = text[/MP for ([^<]+)</,1]
      mp_for.strip.gsub(' & ',' and ')
    else
      nil
    end
  end

  def map_attributes
    {
    :biography => :bio
    }
  end

  def get_constituency details, ppc
    if details.include?('Liberal Democrat candidate for ')
      constituency = details.split('Liberal Democrat candidate for ').last
      if ppc.name == 'Peter Fisher' && constituency == 'Ribble Valley'
        'South Ribble'
      else
        constituency
      end
    elsif details.include?('PPC for ')
      details.split('PPC for ').last
    elsif details.include?('MP for ')
      details.split('MP for ').last
    elsif ppc.name[/morton/i]
      'Pudsey'
    else
      nil
    end
  end

end

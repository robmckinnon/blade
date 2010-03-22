require 'yaml'
require 'open-uri'
require 'rubygems'
require 'hpricot'
require 'date'
require 'twfy'

begin
  require 'active_support/core_ext/object/blank'
rescue Exception => e
  begin
    require 'active_support'
  rescue Exception => e
    require 'activesupport'
  end
end
require 'morph'

class Ppc
  include Morph
end

module Twfy
  class MP
    attr_reader :constituency
  end
  class Constituency
    attr_reader :name
  end
end

module Ppcs; end
  
module Ppcs::ParserBase
  
  def perform scrape_result
    resources = scrape_result.scraped_resources
    not_processed = []
    ppcs = []
    resources.each do |resource|
      parse_resource resource, ppcs, not_processed
    end
    log_not_processed not_processed
    save_mps_info ppcs
    ppcs = check_one_ppc_per_constituency(ppcs)

    @attributes ||= nil
    write ppcs, @attributes unless ppcs.empty?
  end
  
  def check_one_ppc_per_constituency ppcs
    grouped = ppcs.group_by(&:constituency)
    grouped.to_a.each do |constituency, list|
      if list.size > 1
        ppc = list.select {|x| (!x.respond_to?(:mp_for) || x.mp_for.nil?) && !x.name[/^Dr /]}
        if ppc.size == 1
          grouped[constituency] = ppc
        else
          if constituency == 'South East Cambridgeshire'
            grouped[constituency] = ppc.select {|x| x.name == 'Jonathan Chatfield'}
          elsif constituency == 'Bradford South'
            grouped[constituency] = ppc.select {|x| x.name == 'Michael Doyle'}
          else
            puts "Too many in: #{constituency}"
            puts list.collect(&:name).join(', ')
          end
        end
      end
    end
    ppcs = grouped.to_a.collect{|x| x[1]}.flatten
  end
  
  def save_mps_info
    if @mps_info
      file = "#{ppcs.last.twfy_party.downcase.gsub(' ','_')}_mps_info.yml"
      File.open(file, 'w') {|f| f.write @mps_info.to_yaml }
    end
  end

  def log_not_processed not_processed
    unless not_processed.empty?
      puts 'NOT PROCESSED: '
      not_processed.each {|x| puts x.inspect }
    end
  end

  def parse_resource resource, ppcs, not_processed
    text = resource.contents
    if text.blank?
      puts 'text is blank for: ' + resource.inspect
      not_processed << resource
    else
      preprocess_text text
      doc = Hpricot(text)
      
      if ppc = populate_ppc(doc, Ppc.new, resource.git_path)
        normalize_constituency ppc
        normalize_name ppc
        set_twfy_attributes ppc
        ppcs << ppc
      else
        not_processed << resource
      end
    end
  end

  def preprocess_text text
    text
  end

  def populate_ppc doc, ppc, git_path
  end

  def normalize_constituency ppc
    ppc.constituency = ppc.constituency.strip.gsub(' & ',' and ').squeeze(' ')
  end
  
  NAME_SUFFIX = /(\s[A-Z]+)+$/
  NAME_TITLE = /^(Dr|Mr|Mrs|Miss|Ms|Sir)\s/

  def normalize_name ppc
    if suffix = ppc.name[NAME_SUFFIX]
      suffix.strip!
      ppc.name_suffix = suffix unless suffix == 'MP'
      ppc.name = ppc.name.sub(NAME_SUFFIX, '')
    end
    if title = ppc.name[NAME_TITLE]
      ppc.name_title = title.strip
      ppc.name = ppc.name.sub(NAME_TITLE, '')
    end
    
    ppc.name = ppc.name.strip
    
    ppc.twfy_name = case ppc.name
      when 'Greg Barker'
        'Gregory Barker'
      when 'Bill Cash'
        'William Cash'
      when 'Mike Penning'
        'Michael Penning'
      when 'Ed Vaizey'
        'Edward Vaizey'
      when 'Rob Wilson'
        'Robert Wilson'
      when 'Chris Huhne'
        'Christopher Huhne'
      when 'Dan Rogerson'
        'Daniel Rogerson'
      when 'Jenny Willott'
        'Jennifer Willott'
      when 'Lembit Opik'
        "Lembit \xD6pik"
      when 'Ming Campbell'
        'Menzies Campbell'
      when 'Nick Clegg'
        'Nicholas Clegg'
      when 'Vince Cable'
        'Vincent Cable'
      when 'Andrew Mackinlay'
        'Andrew MacKinlay'
      when 'Andy Love'
        'Andrew Love'
      when 'Andy Slaughter'
        'Andrew Slaughter'
      when 'Brian Donohoe'
        'Brian H Donohoe'
      when 'Ed Balls'
        'Edward Balls'
      when 'Ed Miliband'
        'Edward Miliband'
      when 'Huw Irranca Davies'
        'Huw Irranca-Davies'
      when 'Jim Hood'
        'Jimmy Hood'
      when 'Jim McGovern'
        'James McGovern'
      when 'Jonathan Shaw'
        'Jonathan R Shaw'
      when 'Kaili Mountford'
        'Kali Mountford'
      when 'Pat McFadden'
        'Patrick McFadden'
      when 'Rob Flello'
        'Robert Flello'
      when 'Steve McCabe'
        'Stephen McCabe'
      when 'Steve Pound'
        'Stephen Pound'
      when 'Sian James'
        'Siân James'
      when 'Sion Simon'
        'Siôn Simon'
      else
      # when 'Michael Crockart Edinburgh West'
      # when 'Ann McKechin Glasgow North'
      # when 'Anne Begg Aberdeen South'
      # when 'Bob Blizzard Waveney'
      # when 'Joe Benton  Bootle'
      # when 'Sharon Hodgson Gateshead East and Washington West'
      # when 'Sylvia Heal Halesowen and Rowley Regis'
        nil
    end
  end

  def set_twfy_attributes ppc
    name = (ppc.respond_to?(:twfy_name) && ppc.twfy_name) ? ppc.twfy_name : ppc.name

    if ppc.respond_to?(:mp_for) && ppc.mp_for && (info = mp_info(name, ppc.twfy_party, ppc.mp_for))
      ppc.guardian_mp_summary = info.guardian_mp_summary
      ppc.expenses_url = info.expenses_url
      ppc.bbc_profile_url = info.bbc_profile_url
      ppc.mp_website = info.mp_website
      ppc.wikipedia_url = info.wikipedia_url
    end
  end

  def set_image ppc, img, base
    if img
      image = img['src']
      ppc.image = image[/http/] ? image : "#{base}#{image}"
    end
  end

  def write ppcs, attributes
    ppcs = ppcs.sort_by(&:constituency)

    attributes ||= %w[constituency name_title name name_suffix mp_for
        email website telephone address biography fax image
        guardian_mp_summary expenses_url bbc_profile_url 
        mp_website mp_wikipedia_url]
    File.open('data.tsv','w') do |f|
      f.write attributes.join("\t")
      f.write "\n"
      ppcs.each do |ppc|
        values = attributes.map do |attribute|
          attribute = attribute.to_sym
          if ppc.respond_to?(attribute)
            value = ppc.send(attribute)
          elsif map_attributes[attribute] && ppc.respond_to?(map_attributes[attribute])
            value = ppc.send(map_attributes[attribute])
          else
            value = ''
          end
          value = value.to_s.gsub("\t",'[tab]')

          if attribute == :telephone || attribute == :fax
            if !value.blank? && !value.include?(' ') && value.size > 5
              value = value[0..4] + ' ' + value[5..(value.size - 1)]
            end
          end
          value
        end
        f.write values.join("\t")
        f.write "\n"
      end
    end
  end

  def twfy
    @twfy_key ||= open(File.expand_path(RAILS_ROOT+ '/config/twfy_key.txt')).read.strip
    @twfy ||= Twfy::Client.new(@twfy_key)
    @twfy
  end

  def party_mps party
    @mps ||= Hash.new {|h,v| h[v] = Hash.new {|h1,v1| h1[v1] = [] } }
    file = "#{party.downcase.gsub(' ','_')}_mps.yml"

    if @mps.size == 0 && File.exist?(file)
      @mps[party] = YAML.load_file(file)
    end

    if !@mps.has_key?(party)
      unless @mps.has_key?(party)
        puts "lookup mps: #{party}"
        mps = twfy.mps(:party => party, :date => Date.today)
        mps.each do |mp|
          constituency = mp.constituency.name
          unless constituency[/^Ynys\s/]
            puts "lookup mp: #{constituency}"
            mp = twfy.mp(:constituency => constituency)
            @mps[party][mp.full_name] << mp
          end
        end
      end
      File.open(file, 'w') {|f| f.write @mps[party].to_yaml }
    end

    @mps[party]
  end

  def normalize name
    name.gsub(' & ',' and ').gsub(',','')
  end
  
  def mp_info name, party, constituency
    info_key = name + ' ' + constituency
    file = "#{party.downcase.gsub(' ','_')}_mps_info.yml"

    @mps_info ||= Hash.new {|h,v| h[v] = {} }

    if @mps_info.size == 0 && File.exist?(file)
      @mps_info = YAML.load_file(file)
    end

    if !@mps_info.has_key?(info_key)
      if info_key == 'Albert Owen Ynys Mon'
        @mps_info[info_key] = twfy.mp_info(:id => '11148')
      elsif info_key == 'Siân James Swansea East'
        @mps_info[info_key] = twfy.mp_info(:id => '11863')
      elsif info_key == 'Siôn Simon Birmingham Erdington'
        @mps_info[info_key] = twfy.mp_info(:id => '11225')
      elsif info_key == 'Sylvia Heal Halesowen and Rowley Regis'
        @mps_info[info_key] = twfy.mp_info(:id => '10266')
      elsif info_key == 'Michael Lord Central Suffolk and North Ipswich'
        @mps_info[info_key] = twfy.mp_info(:id => '10370')
      elsif info_key == 'Alan Haselhurst Saffron Walden'
        @mps_info[info_key] = twfy.mp_info(:id => '10263')
      elsif info_key != 'Michael Crockart Edinburgh West'
        puts "missing info for: #{info_key}"
        mp = party_mps(party)[name]
        if mp.size > 1
          match = mp.select do |member|
            member_constituency = normalize(member.constituency.name)
            member_constituency == normalize(constituency)
          end
          if match.size == 1
            mp = match
          else
            puts "#{name} | #{party} | #{constituency}"
            puts mp.collect{|x| x.constituency.name}.join(' | ')
            raise mp.inspect
          end
        end
        mp = mp.first
        puts "lookup info: #{name}"
        info = mp.info
        @mps_info[info_key] = info
      end
    end

    @mps_info.has_key?(info_key) ? @mps_info[info_key] : nil
  end

end

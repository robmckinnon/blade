require 'rubygems'
require 'hpricot'
require 'open-uri'

DEBUGZ = true

module LordsInterests

  class RegisterParser

    # parameters: Hpricot doc
    def parse name, text
      text.gsub!('	',' ') # remove weird whitespace
      text.gsub!('<b>*</b></b>16(b)&nbsp;&nbsp;Voluntary organisations<br>',
        '</b><p><b>*16(b)  Voluntary organisations</b></p><ul>')
      text.gsub!(/<br>\n<\/b>/, "</b>\n<br>")
      text.gsub!('&nbsp;',' ')
      text.gsub!(/<b>\s*(\([^<]+\))\s*<\/b>/) {|x| "#{$1}" }

      text.gsub!(/\(<b>([^<]+)<\/b>\)\n?\s*<(br|\/ul)>/) {|x| "(#{$1})<#{$2}>" }

      text.gsub!(/<b>\s*(Enterprise Champion [^<]+)<\/b>/, '\1')
      text.gsub!(/<b>(Amshold Limited [^<]+)<\/b>/, '\1')
      text.gsub!(/<b>([^<]+)<\/b>\n\s*<\/ul>/) {|x| "#{$1}\n</ul>" }
      text.gsub!(/<b>(.)<\/b>/, '\1')
      text.gsub!(/<b>(\(unpaid\)[^<]+)<\/b>/, '\1')
      text.gsub!('<b>paid</b>','paid')
      text.gsub!('<b>unpaid</b>','unpaid')
      text.gsub!(/<a[^>]+>([^<]+)<\/a>/, '\1')
      text.gsub!(/<ul>\n<br>/, "<ul>\n")
      text.gsub!(/<br>\n\s*<\/p>/, "</p>")
      text.gsub!('<p></p><p>','<p>')
      text.gsub!(/<p>\n<\/p><p>/,'<p>')
      text.gsub!('<br><br>','<br>')
      text.gsub!('<sup>','')
      text.gsub!('</sup>','')
      text.gsub!('<i>','')
      text.gsub!('</i>','')
      text.gsub!('<u>','')
      text.gsub!('</u>','')
      text.gsub!(/<b>\s*(\([^<]+\))\s*<br>\n\s*<\/b>/) {|x| "#{$1}<br>\n" }
      text.gsub!(/<br>\n<\/ul>/) {|x| "\n</ul>" }
      text.gsub!(/<br>\n\s*<br>\n/, "<br>\n")
      text.gsub!(/<br>\n<b>([^<]+)<\/b>/) {|x| "<br>\n#{$1}" }
      text.gsub!('<br>','<br/>')
      doc = Hpricot.XML text
      File.open('/Users/x/apps/scalpel/public/'+name+'.hpricot.htm','w') {|f|
        f.write doc.to_s
      }
      doc.at('/html/body/div/div[3]/table[2]/tbody/tr[2]/td/table/tbody/tr/td')
      @element_stack = []
      @state = nil
      @previous_state = nil
      @started = false
      @finished = false
      @result = []
      handle_children doc
      if @previous_state == :lord_name
        add "</items>\n</entry>\n<entry>"
      else
        add "</items>\n</category>\n</categories>\n</entry>"
      end

      @result
    end

    def started?
      puts "<state>#{@element_stack.inspect}</state>\n" if DEBUGZ
      @element_stack ==       %w[p b]   ||
      @element_stack ==    %w[br p b] ||
      @element_stack == %w[br br p b] ||
      @element_stack == %w[br br p p b]
    end

    def sample_state text
      puts "<state>#{@element_stack.inspect}</state>\n" if DEBUGZ
      state = if @element_stack.last(3) == %w[br p b]
        lord_or_category text
      else
        examine_state text
      end
      @element_stack.clear
      state
    end

    def lord_or_category text
      text[/^[A-Z]/] ? :lord_name : :category
    end

    def lord_category_or_content text
      if text[/^\d\d\(|^[\*]\d\d/]
        :category
      elsif text[/^[A-Z][A-Z]/]
        :lord_name
      else
        :content
      end
    end

    def category_or_content text
      if text[/^\d\d\(|^[\*]\d\d/]
        :category
      else
        :content
      end
    end

    def category_or_item text
      if text[/^\d\d\(|^[\*]\d\d/]
        :category
      else
        :item
      end
    end

    def examine_state text
      stack = @element_stack.uniq
      case stack
        when    %w[p br b]
          lord_or_category(text)
        when    %w[br p b]
          lord_or_category(text)
        when       %w[p b]
          lord_or_category(text)
        when %w[p br ul b]
          lord_or_category(text)
        when         %w[b]
          lord_or_category(text)

        when      %w[p ul b]
          lord_category_or_content(text)
        when         %w[p b]
          :category
        when        %w[br b]
          category_or_content(text)
        when        %w[ul b]
          :category
        when      %w[ul p b]
          :category
        when   %w[br p ul b]
          :category

        when    %w[p ul]
          category_or_content(text)
        when      %w[ul p]
          :content
        when %w[br p ul]
          :content
        when   %w[br ul p]
          :content
        when      %w[ul]
          :content
        when    %w[p ul br]
          :content

        when   %w[br p td]
          :item
        when %w[blockquote p]
          :content

        when %w[p]
          if @state == :category
            :content
          elsif @state == :content || @state == :item
            :item
          else
            raise @state.to_s + ' ' + stack.inspect + ' ' + text
          end
        when %w[br]
          category_or_item text
        when %w[td]
          :item
        else
          if text && text.gsub(' ','').length > 0
            # if (@element_stack == %w[p p ul p b] || @element_stack == %w[p p p ul b])
              # :category
            # else
              raise stack.inspect + ' "' + text + '"'
            # end
          else
            nil
          end
      end
    end

    def start_tags state, text
      case state
        when :lord_name
          case @state
            when nil
              "<entry>\n<lord_name>"
            when :item
              "</items>\n</category>\n</categories>\n</entry>\n<entry>\n<lord_name>"
            when :content
              if @previous_state == :lord_name
                "</items>\n</entry>\n<entry>\n<lord_name>"
              else
                "</items>\n</category>\n</categories>\n</entry>\n<entry>\n<lord_name>"
              end
            when :category
              "</items>\n</category>\n</categories>\n</entry>\n<entry>\n<lord_name>"
            else
              raise @state.to_s + ' ' + text
          end
        when :category
          if @state == :lord_name
            "<categories>\n<category>\n<category_name>"
          elsif @state == :item
            "</items>\n</category>\n<category>\n<category_name>"
          elsif @state == :category
            "</items>\n</category>\n<category>\n<category_name>"
          elsif @state == :content
            "</items>\n</category>\n<category>\n<category_name>"
          else
            raise @state.to_s
          end
        when :content
          if @state == :item
            "<item>"
          else
            "<items>\n<item>"
          end
        when :category
          if @state == :item
            "</items>\n<category>"
          else
            '<category>'
          end
        else
          "<#{state}>"
      end
    end

    def end_tags state
      case state
        when :content
          '</item>'
        when :category
          '</category_name>'
        else
          "</#{state}>"
      end
    end

    def update_state node
      case node.name
        when 'p'
          # add "p\n"
          @element_stack << 'p'
        when /^b|ul|br|td$/
          # add "#{node.name}\n"
          @element_stack << node.name
        else
      end if node.elem?
    end

    def add text
      puts text if DEBUGZ
      @result << text.gsub(' & ',' &amp; ').gsub(/([A-Z])&([A-Z])/,'\1&amp;\2')
    end

    def handle_text node
      if !@started
        puts node.to_s if DEBUGZ
        @started = started?
        @element_stack.clear
      else
        text = node.to_s.strip.gsub(/\r/,'').gsub(/\n/,' ').squeeze(' ')
        if state = sample_state(text)
          add "#{start_tags(state,text)}#{text}#{end_tags(state)}"
          @previous_state = @state
          @state = state
        end
      end
    end

    def has_children? node
      node.elem? && node.children
    end

    def is_text? node
      node.text? && !node.to_s.strip.empty?
    end

    def handle_children node
      node.children.each do |node|
        @finished = true if @started && (is_text?(node) && (node.to_s == 'A-Z Index' || node.to_s[/Parliamentary copyright 2010/]))
        unless @finished
          update_state(node)
          handle_children(node) if has_children? node
          handle_text(node) if is_text? node
        end
      end
    end
  end
end

lines = []
4.upto(27) do |index|
# 22.upto(22) do |index|
  index = "0#{index}" if index < 10
  name = "www.publications.parliament.uk/pa/ld/ldreg/reg#{index}.htm"
  puts name
  lines += LordsInterests::RegisterParser.new.parse name, open("http://localhost:9999/#{name}").read
end

xml = "<entries>\n#{lines.flatten.join('')}\n</entries>"
File.open('/Users/x/apps/scalpel/govtracedata/parsers/lords_interests/registry.xml','w') {|f| f.write xml }


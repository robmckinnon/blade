module Appc; end
  
class Appc::RegisterParse

  def perform result
    resources = result.scraped_resources
    text = resources.first.contents
    lines = text.split("\n")
    # lines = lines.select {|x| x.starts_with? ''}
    splits = []

    rows = []
    numbers = []
    lines.collect do |line|
      if line.starts_with?('   ')
        line = line.sub('   ','   '+'  ')
      end
      if line[/Fee-Paying clients for whom UK PA consultancy services provided this quarter/]
        @start = true
      elsif line[/Fee-Paying Clients for whom only UK monitoring services provided this quarter/]
        @start = false
      end
      if @start && !line[/Fee-Paying clients for whom UK PA consultancy services provided this quarter/]
        parts = Parser.values_from_line(line).select{|x| !x.blank?}
        bullet = false
        parts = parts.map do |x|
          if x.strip == "\357\202\267" || x.strip == "\357\202\247"
            bullet = true
            nil
          else
            if x[/^ (.+)/]
              bullet = true
              value = $2
            else
              value = x
            end
            item = [bullet, line.index(x), value]
            bullet = false
            item
          end
        end.compact
        numbers << parts.collect(&:second)
        rows << parts
      end      
    end

    freq = numbers.flatten.group_by(&:to_i)

    freq.keys.sort.each do |number|
      count = ''
      (freq[number].size / 5).times {|i| count += '|'}
      puts "#{number} #{count}"
    end

    puts '==='
    freq = numbers.flatten.group_by do |x|
      if x <= 13
        5
      elsif x > 23 && x < 53
        43
      elsif x > 60
        79
      else
        x
      end
    end

    freq.keys.sort.each do |number|
      puts "#{number} #{freq[number].size}"
    end

    first = []
    second = []
    third = []

    rows.each do |row|
      row.each do |cell|
        x = cell[1]
        if x <= 13
          5
          first << cell
        elsif x > 23 && x < 53
          43
          second << cell
        elsif x > 60
          79
          third << cell
        else
          x
        end
      end
    end
    
    result = []
    first.each do |cell|
      if cell[0]
        puts result.join(' ').squeeze(' ').strip
        puts "\n"
        result = []
        result << cell.last
      else
        result << cell.last
      end
    end
    puts result.join(' ').squeeze(' ').strip
    
  end

end

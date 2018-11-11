EMPTY = []

def score(game, word)
  game = game.transform_values(&:dup)
  word.each_char.sum { |c| game.fetch(c, EMPTY).shift || 0 }
end

def normalize_line(line)
  line.chomp.gsub(/./) do |c|
    if c.ord == 0x3000
      " "
    elsif 0xfee0 < c.ord
      ascii_ord = c.ord - 0xfee0
      if ascii_ord < 0 || ascii_ord > 127
        raise "unexpcted: #{ascii_ord} from #{c.inspect}"
      end
      ascii_ord.chr.upcase
    else
      raise "Uhm, wut? #{c.inspect}"
    end
  end
end


def parse(game)
  game
    .lines
    .map { |line| normalize_line(line).split }
    .reject { |row| row.length.zero? }
    .transpose
    .flat_map { |*vals, base|
      base = base.to_i
      vals.map do |val|
        next [val, base] if val.size == 1
        raise "Wat: #{val.inspect}" unless val.size == 3
        char, op, arg = val.chars
        [char, base.send(op, arg.to_i)]
      end
    }
    .group_by(&:first)
    .transform_values { |values| values.map &:last }
end

def each_word(file_names, &block)
  return to_enum __method__, file_names unless block_given?
  file_names.each do |file_name|
    File.open file_name, 'r' do |file|
      file.each_line { |line| block.call line.strip.upcase }
    end
  end
end

# example board
parsed = parse <<~GAME
Ｑ＋２　Ｔ　　　Ｌ　　　Ｇ　　　
Ｃ　　　Ｄ　　　Ｂ　　　Ｍ　　　

５　　　４　　　３　　　２
GAME

parsed = parse $stdin.read

words =
  each_word([
    "/usr/share/dict/words",
    File.expand_path("word_list", __dir__),
  ])
  .group_by { |word| score parsed, word }
  .max
  .last
  .uniq
  .sort

if words.empty?
  $stderr.puts "No words found :("
  exit 1
end

puts "SCORE: #{score parsed, words.first}"
puts words

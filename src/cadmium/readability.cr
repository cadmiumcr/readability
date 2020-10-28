require "cadmium_util"
require "json"

module Cadmium
  module Readability
    VERSION = "0.9.0"

    struct Statistics
      include JSON::Serializable
      getter number_of_words : Int32
      getter number_of_sentences : Int32
      getter number_of_paragraphs : Int32
      getter frequencies : Hash(String, Int32)
      getter number_of_long_words : Int32    # more than 6 characters (for LIX)
      getter number_of_complex_words : Int32 # for Fog Index
      getter number_of_unique_words : Int32
      getter number_of_characters : Int32
      getter average_number_of_words_per_sentence : Float32
      getter number_of_syllables : Int32
      getter average_number_of_syllables_per_word : Float32
      getter average_number_of_characters_per_word : Float32
      # The average number of sentences per 100 words. Useful for the Coleman-Liau
      # and Linsear Write score calculation
      getter number_of_sentences_per_hundred_words : Float32
      # The percentage of words that are defined as "complex" for the purpose of
      # the Fog Index. This is non-hyphenated words of three or more syllabes.
      getter percent_fog_complex_words : Float32

      def initialize(text : String, word_tokenizer = Tokenizer::Aggressive.new(lang: :en), sentence_tokenizer = Tokenizer::Sentence.new)
        words = word_tokenizer.tokenize(text)
        sentences = sentence_tokenizer.tokenize(text)
        paragraphs = Cadmium::Util::Paragraph.paragraphs(text)
        @number_of_words = words.size
        @number_of_sentences = sentences.size
        @number_of_paragraphs = paragraphs.size
        @number_of_characters = text.size
        @average_number_of_words_per_sentence = (@number_of_words / @number_of_sentences).to_f32
        @number_of_sentences_per_hundred_words = (@number_of_sentences / (@number_of_words / 100)).to_f32
        @number_of_syllables = 0
        @number_of_long_words = 0
        @number_of_unique_words = 0
        @number_of_complex_words = 0

        @frequencies = Hash(String, Int32).new
        # Count words for frequencies + long_words + complex_words
        words.each do |word|
          # up frequency counts
          @frequencies.has_key?(word) ? (@frequencies[word] += 1) : (@frequencies[word] = 1)
          # character counts
          characters = word.size

          if characters > 6
            @number_of_long_words += 1 # for LIX Index
          end

          # syllable counts
          syllables = Cadmium::Util::Syllable.syllables(word)
          @number_of_syllables += syllables
          if syllables > 2 && !word.includes?('-')
            @number_of_complex_words += 1 # for Fog Index
          end
        end
        @average_number_of_syllables_per_word = (@number_of_syllables / @number_of_words).to_f32
        @average_number_of_characters_per_word = (@number_of_characters / @number_of_words).to_f32
        @number_of_unique_words = @frequencies.keys.size
        @percent_fog_complex_words = ((@number_of_complex_words.to_f / words.size.to_f) * 100).to_f32
      end
    end

    struct GradeLevels
      include JSON::Serializable
      getter flesch : Float32
      getter kincaid : Float32
      getter gunning_fog : Float32
      getter smog : Float32
      getter ari : Float32
      getter coleman_liau : Float32

      # getter rix : Float32
      # getter forcast : Float32
      # getter powers_sumner_kearl : Float32
      # getter raygor : Float32
      # getter fry : Float32

      def initialize(statistics : Statistics)
        @flesch = flesch(statistics.average_number_of_words_per_sentence, statistics.average_number_of_syllables_per_word)
        @kincaid = kincaid(statistics.average_number_of_syllables_per_word, statistics.average_number_of_words_per_sentence)
        @gunning_fog = fog(statistics.average_number_of_words_per_sentence, statistics.percent_fog_complex_words)
        @smog = smog(statistics.number_of_sentences, statistics.number_of_complex_words)
        @ari = ari(statistics.average_number_of_characters_per_word, statistics.average_number_of_words_per_sentence)
        @coleman_liau = coleman_liau(statistics.number_of_words, statistics.average_number_of_characters_per_word, statistics.number_of_sentences_per_hundred_words)
        # @rix = rix()
        # @forcast = forcast()
        # @powers_sumner_kearl = powers_sumner_kearl()
        # @raygor = raygor()
        # @fry = fry()
      end

      # Flesch reading ease of the text sample. A higher score indicates text
      # that is easier to read. The score is on a 100-point scale, and a score
      # of 60-70 is regarded as optimal for ordinary text.
      def flesch(average_number_of_words_per_sentence, average_number_of_syllables_per_word) : Float32
        (206.835 - (1.015 * average_number_of_words_per_sentence) - (84.6 * average_number_of_syllables_per_word)).round(2).to_f32
      end

      # Flesch-Kincaid level of the text sample. This measure scores text based
      # on the American school grade system; a score of 7.0 would indicate that
      # the text is readable by a seventh grader. A score of 7.0 to 8.0 is
      # regarded as optimal for ordinary text.
      def kincaid(average_number_of_syllables_per_word, average_number_of_words_per_sentence) : Float32
        ((11.8 * average_number_of_syllables_per_word) + (0.39 * average_number_of_words_per_sentence) - 15.59).round(2).to_f32
      end

      # The Gunning Fog Index of the text sample. The index indicates the number
      # of years of formal education that a reader of average intelligence would
      # need to comprehend the text. A higher score indicates harder text; a
      # value of around 12 is indicated as ideal for ordinary text.
      def fog(words_per_sentence, percent_fog_complex_words) : Float32
        ((words_per_sentence + percent_fog_complex_words) * 0.4).round(2).to_f32
      end

      # The SMOG grade of the text sample. The grade indicates the approximate
      # representation of the US grade level needed to comprehend the text.
      # A higher score indicates harder text; a value of 8 or less is a
      # good standard for ordinary text. Evaluating SMOG requires
      # a text containing at least 30 sentences.

      def smog(number_of_sentences, number_of_complex_words) : Float32
        if number_of_sentences < 30
          return 0.to_f32
        end
        (1.0430 * Math.sqrt(number_of_complex_words * 30 / number_of_sentences) + 3.1291).to_f32
      end

      # The Automated Readability Index of the text sample.
      # The score gives an indication of how difficult the page is to read.
      # Each score can be matched to an equivalent reading ability level.
      # ARI uses a scale based on age in full-time education.

      def ari(average_number_of_characters_per_word, average_number_of_words_per_sentence) : Float32
        result = 4.71 * (average_number_of_characters_per_word) + 0.5 * (average_number_of_words_per_sentence) - 21.43
        result.finite? ? result.round(2).to_f32 : 0.0.to_f32
      end

      # The Coleman-Liau score of the text sample.
      # The score gives an indication of the US grade level needed to comprehend the text.
      # A higher score indicates harder text; a value of 8 or less is a
      # good standard for ordinary text. Calculating Coleman-Liau requires
      # a text containing at least 100 words.

      def coleman_liau(number_of_words, average_number_of_characters_per_word, sentences_per_hundred_words) : Float32
        if number_of_words < 100
          return 0.to_f32
        end
        (0.0588 * (average_number_of_characters_per_word * 100) - 0.296 * sentences_per_hundred_words - 15.8).round(2).to_f32
      end
    end

    struct Scores
      include JSON::Serializable
      # getter spache : Float32
      # getter new_dale_chall : Float32
      getter lix : Float32
      getter linsear_write : Float32

      def initialize(statistics : Statistics)
        # @spache = spache()
        # @new_dale_chall = new_dale_chall()
        @lix = lix(statistics.number_of_words, statistics.number_of_sentences, statistics.number_of_long_words)
        @linsear_write = linsear_write(statistics.number_of_words, statistics.percent_fog_complex_words, statistics.number_of_sentences_per_hundred_words)
      end

      # The LIX score of the text sample.
      # The score gives an indication of reading level required by readers to understand the text.
      # A higher score indicates easier to read text; a value of 40 or more is a
      # good standard for ordinary text.

      def lix(number_of_words, number_of_sentences, number_of_long_words) : Float32
        result = (number_of_words / number_of_sentences).to_f + ((number_of_long_words * 100) / number_of_words).to_f
        result.finite? ? result.round(2).to_f32 : 0.0.to_f32
      end

      # The Linsear Write score of the text sample.
      # The score gives an indication of the reading complexity of the text.
      # The score should be calculated in an exact 100 words sample.
      # The following formula uses instead calculated averages.

      def linsear_write(number_of_words, percent_fog_complex_words, sentences_per_hundred_words) : Float32
        if number_of_words < 100
          return 0.to_f32
        end
        result = ((100 - percent_fog_complex_words + (3 * percent_fog_complex_words)) / sentences_per_hundred_words)
        result = result.finite? ? result.round(2) : 0.0
        result > 20 ? (result / 2).to_f32 : ((result / 2) - 1).to_f32
      end
    end

    struct Report
      include JSON::Serializable
      getter statistics : Statistics
      getter grade_levels : GradeLevels
      getter scores : Scores
      getter reading_time : Int32  # In minutes
      getter speaking_time : Int32 # In minutes

      def initialize(text : String, word_tokenizer = Tokenizer::Aggressive.new, sentence_tokenizer = Tokenizer::Sentence.new)
        @statistics = Statistics.new(text, word_tokenizer, sentence_tokenizer)
        @grade_levels = GradeLevels.new(@statistics)
        @scores = Scores.new(@statistics)
        @reading_time = (@statistics.number_of_words / 200).to_i
        @speaking_time = (@statistics.number_of_words / 150).to_i
      end
    end
  end
end

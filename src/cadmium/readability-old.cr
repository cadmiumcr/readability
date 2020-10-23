require "cadmium_util"

module Cadmium
  # A syntactical analyzer that helps determine the readibility
  # of a block of text.

  # https://www.gavagai.io/
  # readable.com
  # Comprehensive Readability Analysis
  # Free Tools
  # Keyword Density Analysis
  # Gender Analysis
  # Profanity Detector
  # Buzzword Detector
  # Stop Word Detector
  # Hedge Word Detector
  # Lazy Word Detector
  # Names Detector
  # Transition Word Detector
  # Word List Tools
  # Dale-Chall Word Analysis
  # Spache Word Analysis
  # Ogden Word Analysis
  # Dolch Word Analysis
  # Fry Word Analysis

  # Readability Grade Levels
  # Flesch-Kincaid Grade Level	4.9
  # Gunning Fog Index	7.3
  # Coleman-Liau Index	6.3
  # SMOG Index	8.3
  # Automated Readability Index	3.4
  # FORCAST Grade Level	9.9
  # Powers Sumner Kearl Grade	4.8
  # Rix Readability	5
  # Raygor Readability	n/a
  # Fry Readability	5

  # Readability Scores
  # Readable Rating	A
  # Flesch Reading Ease	76.0
  # CEFR Level	A1
  # IELTS Level	0-2
  # Spache Score	4.0
  # New Dale-Chall Score	3.6
  # Lix Readability	26
  # Lensear Write	96.4

  # Text Statistics
  # Word Count	55
  # Sentence Count	6
  # Paragraph Count	2
  # Sentences > 30 Syllables	0	0%
  # Words > 12 Letters	0	0%
  # Adverb Count
  # Cliché count

  # Readability Issues
  # Sentences > 30 Syllables	0	0%
  # Sentences > 20 Syllables	2	33%
  # Words > 4 Syllables	0	0%
  # Words > 12 Letters	0	0%
  # Writing Style Issues
  # Passive Voice Count	1	4%
  # Adverb Count	2	4%
  # Cliché Count	0	0%
  # Text Density Issues
  # Characters per Word	4.3
  # Syllables per Word	1.4
  # Words per Sentence	9.2
  # Words per Paragraph	27.5
  # Sentences per Paragraph	3.0

  #   Text Statistics
  # Character Count	237
  # Syllable Count	79
  # Word Count	55
  # Unique Word Count	41
  # Sentence Count	6
  # Paragraph Count	2
  # Timings
  # Reading Time	0:14
  # Speaking Time	0:26
  # Text Composition
  # Adjectives	6	11%
  # Adverbs	2	4%
  # Conjunctions	1	2%
  # Determiners	6	11%
  # Interjections	0	0%
  # Nouns	11	20%
  # Proper Nouns	0	0%
  # Prepositions	9	16%
  # Pronouns	6	11%
  # Qualifiers	1	2%
  # Verbs	13	24%
  # Unrecognised	0	0%
  # Non-Words

  # Reach is a measure of the proportion of your target audience that can read your content easily. It is currently calibrated against the literate general public, so a reach of 100% means your content is readable by about 85% of the public (that being the percentage that are literate).

  # Tone analysis gives an idea of how formal or how conversational the text looks. Conversational text uses more pronouns and fewer prepositions, among other differences.

  # Sentiment analysis gives an idea of whether the text uses mostly positive language, negative language, or neutral language. For longer pieces, the text is split into three to give sentiment analysis for the beginning, middle and end of the piece.

  # Personalism is the measure of the degree to which you are writing about the reader, rather than yourself. Improve the personalism of your writing by using words like 'you' and 'your' rather than 'we' or 'our'.

  module Readability
    struct Statistics
      getter number_of_words : Int32
      getter number_of_sentences : Int32
      # getter number_of_paragraphs : Int32
      getter frequencies : Hash(String, Int32)
      getter number_of_long_words : Int32
      getter number_of_complex_words : Int32 # for Fog Index
      getter number_of_unique_words : Int32
      getter number_of_characters : Int32
      getter number_of_words_per_sentence : Float32
      getter number_of_syllables : Int32
      getter number_of_syllables_per_word : Float32
      getter number_of_characters_per_word : Float32
      getter number_of_sentences_per_hundred_words: Float32

      def initialize(text : String, word_tokenizer = Tokenizer::Pragmatic.new, sentence_tokenizer = Tokenizer::Sentence.new)
        processed_text = ProcessedText.new(text, word_tokenizer, sentence_tokenizer)
        @number_of_words = processed_text.words.size
        @number_of_sentences = processed_text.sentences.size

        # Count words for frequencies + long_words + complex_words
        processed_text.words.each do |word|
          # up frequency counts
          @frequencies.has_key?(word) ? (@frequencies[word] += 1) : (@frequencies[word] = 1)

          # character counts
          characters = word.size
          if characters > 6
            @long_words += 1 # for LIX Index
          end

          # syllable counts
          syllables = Cadmium::Util::Syllable.syllables(word)
          @syllables += syllables
          if syllables > 2 && !word.includes?('-')
            @complex_words += 1 # for Fog Index
          end
        end

        @number_of_words = processed_text.words.size
        @number_of_words = processed_text.words.size
        @text = text.dup
        @language = language
        @paragraphs = Cadmium::Util::Paragraph.paragraphs(@text)
        @sentences = @text.tokenize(Tokenizer::Sentence)
        @words = [] of String
        @frequencies = {} of String => Int32
        @frequencies["default"] = 0
        @syllables = 0
        @complex_words = 0
        @long_words = 0
        count_words
      end
    end

    # Statistics, number_of_words : Int32, number_of_sentences : Int32, number_of_paragraphs : Int32, frequencies : : Hash(String, Int32), number_of_unique_words : Int32, number_of_characters : Int32, number_of_words_per_sentence : Float32, number_of_syllables : Int32,  number_of_syllables_per_word : Float32,  number_of_characters_per_word : Float32, number_of_sentences_per_hundred_words: Float32
    struct ProcessedText
      getter words : Array(String)
      getter sentences : Array(String)

      def initialize(text : String, word_tokenizer = Tokenizer::Pragmatic.new, sentence_tokenizer = Tokenizer::Sentence.new)
        @words = word_tokenizer.tokenize(text)
        @sentences = sentence_tokenizer.tokenize(text)
      end
    end

    record GradeLevels, flesch_kincaid : Float32, gunning_fog : Float32, smog : Float32, ari : Float32, coleman_liau : Float32, rix : Float32, forcast : Float32, powers_sumner_kearl : Float32, raygor : Float32, fry : Float32
    record Scores, cefr : String, ielts : String, spache : Float32, new_dale_chall : Float32, lix : Float32, lensear_write : Float32

    # record Report, statistics : Statistics, grade_levels : GradeLevels, scores : Scores, reading_time : Int32, speaking_time : Int32 # in seconds 200 wpm
    struct Report
      getter statistics : Statistics
      getter grade_levels : GradeLevels
      getter scores : Scores
      getter reading_time : Int32
      getter speaking_time : Int32 # in seconds 200 wpm

      def initialize(text : String, word_tokenizer = Tokenizer::Pragmatic.new, sentence_tokenizer = Tokenizer::Sentence.new)
        @statistics = Statistics.new(text)
      end
    end

    # Flesch reading ease of the text sample. A higher score indicates text
    # that is easier to read. The score is on a 100-point scale, and a score
    # of 60-70 is regarded as optimal for ordinary text.
    def flesch
      (206.835 - (1.015 * words_per_sentence) - (84.6 * syllables_per_word)).round(2)
    end

    # The Gunning Fog Index of the text sample. The index indicates the number
    # of years of formal education that a reader of average intelligence would
    # need to comprehend the text. A higher score indicates harder text; a
    # value of around 12 is indicated as ideal for ordinary text.
    def fog
      ((words_per_sentence + percent_fog_complex_words) * 0.4).round(2)
    end

    # The SMOG grade of the text sample. The grade indicates the approximate
    # representation of the US grade level needed to comprehend the text.
    # A higher score indicates harder text; a value of 8 or less is a
    # good standard for ordinary text. Evaluating SMOG requires
    # a text containing at least 30 sentences.

    def smog
      if num_sentences < 30
        return 0
      end
      1.0430 * Math.sqrt(@complex_words * 30 / num_sentences) + 3.1291
    end

    # The Automated Readability Index of the text sample.
    # The score gives an indication of how difficult the page is to read.
    # Each score can be matched to an equivalent reading ability level.
    # ARI uses a scale based on age in full-time education.

    def ari
      result = 4.71 * (num_chars / num_words) + 0.5 * (num_words / num_sentences) - 21.43
      result.finite? ? result.round(2) : 0.0
    end

    # The Coleman-Liau score of the text sample.
    # The score gives an indication of the US grade level needed to comprehend the text.
    # A higher score indicates harder text; a value of 8 or less is a
    # good standard for ordinary text. Calculating Coleman-Liau requires
    # a text containing at least 100 words.

    def coleman_liau
      if num_words < 100
        return 0.0
      end
      (0.0588 * (characters_per_word * 100) - 0.296 * sentences_per_hundred_words - 15.8).round(2)
    end

    # The LIX score of the text sample.
    # The score gives an indication of reading level required by readers to understand the text.
    # A higher score indicates easier to read text; a value of 40 or more is a
    # good standard for ordinary text.

    def lix
      result = (num_words / num_sentences).to_f + ((@long_words * 100) / num_words).to_f
      result.finite? ? result.round(2) : 0.0
    end

    # The Linsear Write score of the text sample.
    # The score gives an indication of the reading complexity of the text.
    # The score should be calculated in an exact 100 words sample.
    # The following formula uses instead calculated averages.

    def linsear_write
      if num_words < 100
        return 0
      end
      result = ((100 - percent_fog_complex_words + (3 * percent_fog_complex_words)) / sentences_per_hundred_words)
      result = result.finite? ? result.round(2) : 0.0
      result > 20 ? result / 2 : (result / 2) - 1
    end
  end

  def method_name
  end

  class Analyzer
    getter text : String
    getter paragraphs : Array(String)
    getter sentences : Array(String)
    getter words : Array(String)
    getter frequencies : Hash(String, Int32)
    language : Symbol

    # The constructor accepts the text to be analysed, and returns a report
    # object which gives access to the
    def initialize(text, language = :en)
      @text = text.dup
      @language = language
      @paragraphs = Cadmium::Util::Paragraph.paragraphs(@text)
      @sentences = @text.tokenize(Tokenizer::Sentence)
      @words = [] of String
      @frequencies = {} of String => Int32
      @frequencies["default"] = 0
      @syllables = 0
      @complex_words = 0
      @long_words = 0
      count_words
    end
  end

  class Readability
    getter text : String
    getter paragraphs : Array(String)
    getter sentences : Array(String)
    getter words : Array(String)
    getter frequencies : Hash(String, Int32)
    language : Symbol

    # The constructor accepts the text to be analysed, and returns a report
    # object which gives access to the
    def initialize(text, language = :en)
      @text = text.dup
      @language = language
      @paragraphs = Cadmium::Util::Paragraph.paragraphs(@text)
      @sentences = @text.tokenize(Tokenizer::Sentence)
      @words = [] of String
      @frequencies = {} of String => Int32
      @frequencies["default"] = 0
      @syllables = 0
      @complex_words = 0
      @long_words = 0
      count_words
    end

    # The number of paragraphs in the sample. A paragraph is defined as a
    # newline followed by one or more empty or whitespace-only lines.
    def num_paragraphs
      paragraphs.size
    end

    # The number of sentences in the sample. The meaning of a "sentence" is
    # defined by Cadmium::Tokenizer::Sentence.
    def num_sentences
      sentences.size
    end

    # The number of characters in the sample.
    def num_chars
      text.size
    end

    # The total number of words used in the sample. Numbers as digits are not
    # counted.
    def num_words
      words.size
    end

    # The total number of syllables in the text sample. Just for completeness.
    def num_syllables
      @syllables
    end

    # The number of different unique words used in the text sample.
    def num_unique_words
      @frequencies.keys.size
    end

    # An array containing each unique word used in the text sample.
    def unique_words
      @frequencies.keys
    end

    # The number of occurences of the word +word+ in the text sample.
    def occurrences(word)
      @frequencies[word]
    end

    # The average number of words per sentence.
    def words_per_sentence
      words.size.to_f / sentences.size.to_f
    end

    # The average number of sentences per 100 words. Useful for the Coleman-Liau
    # and Linsear Write score calculation
    def sentences_per_hundred_words
      sentences.size.to_f / (words.size / 100).to_f
    end

    # The average number of characters per word. Useful for the Coleman-Liau
    # score calculation.
    def characters_per_word
      num_chars.to_f / words.size.to_f
    end

    # The average number of syllables per word. The syllable count is
    # performed by Cadmium::Util::Syllable, and so may not be completely
    # accurate, especially if the Carnegie-Mellon Pronouncing Dictionary
    # is not installed.
    def syllables_per_word
      @syllables.to_f / words.size.to_f
    end

    # Flesch-Kincaid level of the text sample. This measure scores text based
    # on the American school grade system; a score of 7.0 would indicate that
    # the text is readable by a seventh grader. A score of 7.0 to 8.0 is
    # regarded as optimal for ordinary text.
    def kincaid
      ((11.8 * syllables_per_word) + (0.39 * words_per_sentence) - 15.59).round(2)
    end

    # Flesch reading ease of the text sample. A higher score indicates text
    # that is easier to read. The score is on a 100-point scale, and a score
    # of 60-70 is regarded as optimal for ordinary text.
    def flesch
      (206.835 - (1.015 * words_per_sentence) - (84.6 * syllables_per_word)).round(2)
    end

    # The Gunning Fog Index of the text sample. The index indicates the number
    # of years of formal education that a reader of average intelligence would
    # need to comprehend the text. A higher score indicates harder text; a
    # value of around 12 is indicated as ideal for ordinary text.
    def fog
      ((words_per_sentence + percent_fog_complex_words) * 0.4).round(2)
    end

    # The SMOG grade of the text sample. The grade indicates the approximate
    # representation of the US grade level needed to comprehend the text.
    # A higher score indicates harder text; a value of 8 or less is a
    # good standard for ordinary text. Evaluating SMOG requires
    # a text containing at least 30 sentences.

    def smog
      if num_sentences < 30
        return 0
      end
      1.0430 * Math.sqrt(@complex_words * 30 / num_sentences) + 3.1291
    end

    # The Automated Readability Index of the text sample.
    # The score gives an indication of how difficult the page is to read.
    # Each score can be matched to an equivalent reading ability level.
    # ARI uses a scale based on age in full-time education.

    def ari
      result = 4.71 * (num_chars / num_words) + 0.5 * (num_words / num_sentences) - 21.43
      result.finite? ? result.round(2) : 0.0
    end

    # The Coleman-Liau score of the text sample.
    # The score gives an indication of the US grade level needed to comprehend the text.
    # A higher score indicates harder text; a value of 8 or less is a
    # good standard for ordinary text. Calculating Coleman-Liau requires
    # a text containing at least 100 words.

    def coleman_liau
      if num_words < 100
        return 0.0
      end
      (0.0588 * (characters_per_word * 100) - 0.296 * sentences_per_hundred_words - 15.8).round(2)
    end

    # The LIX score of the text sample.
    # The score gives an indication of reading level required by readers to understand the text.
    # A higher score indicates easier to read text; a value of 40 or more is a
    # good standard for ordinary text.

    def lix
      result = (num_words / num_sentences).to_f + ((@long_words * 100) / num_words).to_f
      result.finite? ? result.round(2) : 0.0
    end

    # The Linsear Write score of the text sample.
    # The score gives an indication of the reading complexity of the text.
    # The score should be calculated in an exact 100 words sample.
    # The following formula uses instead calculated averages.

    def linsear_write
      if num_words < 100
        return 0
      end
      result = ((100 - percent_fog_complex_words + (3 * percent_fog_complex_words)) / sentences_per_hundred_words)
      result = result.finite? ? result.round(2) : 0.0
      result > 20 ? result / 2 : (result / 2) - 1
    end

    # The percentage of words that are defined as "complex" for the purpose of
    # the Fog Index. This is non-hyphenated words of three or more syllabes.
    def percent_fog_complex_words
      (@complex_words.to_f / words.size.to_f) * 100
    end

    # Return a nicely formatted report on the sample, showing most the useful
    # statistics about the text sample.
    def report
      sprintf "Number of paragraphs           %d \n" +
              "Number of sentences            %d \n" +
              "Number of words                %d \n" +
              "Number of characters           %d \n\n" +
              "Average words per sentence     %.2f \n" +
              "Average syllables per word     %.2f \n\n" +
              "Flesch score                   %2.2f \n" +
              "Flesch-Kincaid grade level     %2.2f \n" +
              "Fog Index                      %2.2f \n" +
              "SMOG grade level               %2.2f \n" +
              "Automated Readability Index    %2.2f \n" +
              "Coleman-Liau Index             %2.2f \n" +
              "LIX Index                      %2.2f \n" +
              "Linsear Write Index            %2.2f \n",
        num_paragraphs, num_sentences, num_words, num_chars,
        words_per_sentence, syllables_per_word,
        flesch, kincaid, fog, smog, ari, coleman_liau, lix, linsear_write
    end

    private def count_words
      @words = Tokenizer::Aggressive.new(lang: @language).tokenize(@text)
      @words.each do |word|
        # up frequency counts
        @frequencies.has_key?(word) ? (@frequencies[word] += 1) : (@frequencies[word] = 1)

        # character counts
        characters = word.size
        if characters > 6
          @long_words += 1 # for LIX Index
        end

        # syllable counts
        syllables = Cadmium::Util::Syllable.syllables(word)
        @syllables += syllables
        if syllables > 2 && !word.includes?('-')
          @complex_words += 1 # for Fog Index
        end
      end
    end
  end
end

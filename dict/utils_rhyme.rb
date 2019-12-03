#!/usr/bin/env ruby

# Rhyming utilities for Rhyme Ninja
# Used both in preprocessing and at runtime

RHYME_SIGNATURE_DICT_FILENAME = "rhyme_signature_dict.txt"

#
# stop words
#

STOP_WORDS_TRIVIAL = ["i", "me", "my", "myself", "we", "our", "ours", "ourselves", "you", "your", "yours", "yourself", "yourselves", "he", "him", "his", "himself", "she", "her", "hers", "herself", "it", "its", "itself", "they", "them", "their", "theirs", "themself", "themselves", "what", "which", "who", "whom", "this", "that", "these", "those", "am", "is", "are", "was", "were", "be", "been", "being", "have", "has", "had", "having", "do", "does", "did", "doing", "a", "an", "the", "and", "but", "if", "or", "as", "of", "at", "by", "for", "with", "to", "from", "then", "so", "than", "i'd", "i've", "i'll", "we'd", "we've", "we'll", "you'd", "you've", "you'll", "he'd", "he'll", "she's", "she'd", "she'll", "it's", "it'd", "it'll", "they'd", "they've", "they'll", "that's", "that'd", "that've", "that'll", "what's", "what've", "what'll", "who's", "who'd", "who've", "who'll", "this'd", "this'll", "that's", "that'd", "that've", "that'll"] # added 's 'd 've 'll forms as appropriate

STOP_WORDS_RELATABLE = ["because", "until", "while", "about", "against", "between", "into", "through", "during", "before", "after", "above", "below", "up", "down", "in", "out", "on", "off", "over", "under", "again", "further", "once", "here", "there", "when", "where", "why", "how", "all", "any", "both", "each", "few", "more", "most", "other", "some", "such", "no", "nor", "not", "only", "own", "same", "too", "very", "can", "will", "just", "dont", "should", "now", "else"] # from https://gist.github.com/sebleier/554280, removed "s" "t", added "themself", and changed "don" to "dont", separated out the ones that ought not show up as related words of anything

def stop_word?(word)
  return STOP_WORDS_TRIVIAL.include?(word) || STOP_WORDS_RELATABLE.include?(word)
end

def relatable_word?(word)
  return ! STOP_WORDS_TRIVIAL.include?(word)
end

#
# blacklist
#

$blacklist = nil
def blacklist()
  if $blacklist.nil?
    $blacklist = load_blacklist_as_array
  end
  return $blacklist
end

def blacklisted?(word)
  return blacklist.include?(word)
end

def load_blacklist_as_array
  if(File.exists?("blacklist.txt"))
     return IO.readlines("blacklist.txt", chomp: true)
  else
    return IO.readlines("dict/blacklist.txt", chomp: true)
  end
end

def delete_blacklisted_words_from_array(array)
  return array.reject { |word| blacklisted?(word) }
end

#
# spelling variants
#

$variants = nil
def variants()
  # hash: word -> [preferred_form alternate_form1 alternate_form2 ...]
  if $variants.nil?
    $variants = load_variants
  end
  return $variants
end

def preferred_form(word)
  forms = variants[word]
  if(forms)
    debug "The preferred form of '#{word}' is '#{forms[0]}'"
    return forms[0]
  else
    return word
  end
end

def all_forms(word)
  forms = variants[word]
  if(forms)
    return forms
  else
    return [word]
  end
end

def load_variants_raw
  if(File.exists?("spelling_variants.txt"))
     return IO.readlines("spelling_variants.txt", chomp: true)
  else
    return IO.readlines("dict/spelling_variants.txt", chomp: true)
  end
end

def load_variants
  variants_array = load_variants_raw
  hash = Hash.new
  for line in variants_array
    if line =~ /\A[[:alpha:]]/ # ignore lines that start with comment characters, punctuation, or numbers
      all_forms = line.split
      for word in all_forms
        hash[word] = all_forms
      end
    end
  end
  return hash
end

#
# consonant clusters and syllabification
#

ALL_INITIAL_CONSONANT_CLUSTERS = [
  'B L', # blue
  'B R', # bread
  'B W', # bueno
  'B Y', # bugle
  'F Y', # few
  'D R', # draw
  'D W', # dwell
  'D Y', # due(1)
  'F L', # flaw
  'F R', # free
  'G L', # glow
  'G R', # grow
  'G W', # guava
  'HH Y', # hue
  'K L', # claw
  'K R', # crow
  'K W', # quick
  'K Y', # cue
  'M Y', # mute
  'P L', # play
  'P R', # pray
  'P W', # pueblo
  'P Y', # pupil
  'S F', # sphere
  'S K', # sky
  'S K L', # sclera
  'S K R', # scrub
  'S K W', # squall
  'S K Y', # skew
  'S P Y', # spume
  'S L', # sled
  'S M', # small
  'S N', # snow
  'S P', # speech
  'S P L', # split
  'S P R', # spray
  'S T', # stay
  'S T R', # straw
  'S W', # sway
  'SH L', # schlock
  'SH M', # schmooze
  'SH R', # shred
  'SH T', # schtick
  'SH W', # schwa
  'T R', # tree
  'T W', # twig
  'TH R', # throw
  'TH W', # thwack
  'V Y', # view
  'ZH W', # joie
] # ARPABET format. source: John Algeo, https://www.tandfonline.com/doi/pdf/10.1080/00437956.1978.11435661 + original work

ALL_FINAL_CONSONANT_CLUSTERS = [
  'B D', # grabbed
  'B Z', # cubs
  'CH T', # patched
  'D TH', # width
  'D TH S', # widths
  'D S T', # midst, rare
  'D Z', # adze
  'DH D', # clothed
  'DH Z', # clothes
  'F S', # graphs
  'F T', # soft
  'F T S', # lifts
  'F TH', # fifth
  'F TH S', # fifths
  'G D', # bogged
  'G Z', # eggs
  'JH D', # bulged
  'K S', # fix
  'K S T', # fixed
  'K S T S', # texts
  'K T', # act
  'K T S', # acts
  'L B', # bulb
  'L B Z', # bulbs
  'L CH', # belch
  'L CH T', # belched
  'L D', # build
  'L D Z', # builds
  'L F', # gulf
  'L F S', # gulfs
  'L F T', # engulfed
  'L F TH', # twelfth, rare
  'L F TH S', # twelfths, rare
  'L JH', # bulge
  'L JH D', # bulged
  'L K', # silk
  'L K S', # silks
  'L K T', # milked
  'L M', # film
  'L M D', # filmed
  'L M Z', # films
  'L N', # kiln, rare
  'L N Z', # kilns, rare
  'L P', # help
  'L P S', # helps
  'L P T', # helped
  'L P T S', # sculpts, rare
  'L S', # else
  'L S T', # pulsed
  'L T', # salt
  'L T S', # salts
  'L TH', # wealth
  'L TH S', # wealths
  # 'L TH T', # wealthed? theoretically possible, but doesn't occur
  'L V', # valve
  'L V D', # solved
  'L V Z', # valves
  'L Z', # feels
  'M D', # framed
  'M F', # triumph
  'M F S', # triumphs
  'M F T', # triumphed
  'M P', # jump
  'M P S', # jumps
  'M P S T', # glimpsed
  'M P T', # jumped
  'M P T S', # tempts
  'M T', # dreamt
  'M Z', # dooms
  'N CH', # punch
  'N CH T', # punched
  'N D', # send
  'N D Z', # sends
  'N JH', # change
  'N JH D', # changed
  'N S', # fence
  'N S T', # fenced
  'N T', # cent
  'N T S', # cents
  'N T S T', # incensed (?)
  'N TH', # tenth
  'N TH S', # tenths
  # 'N TH T', # tenthed? theoretically possible, but doesn't occur
  'N Z', # bronze
  'N Z D', # bronzed
  'NG D', # wronged
  'NG K', # ink
  'NG K S', # inks
  'NG K T', # inked
  'NG K T S', # instincts
  'NG K TH', # length
  'NG K TH S', # lengths
  # 'NG TH T', # lengthed? theoretically possible, but doesn't occur
  'NG Z', # things
  'P S', # lapse
  'P S T', # lapsed
  'P T', # apt
  'P T S', # opts
  'P TH', # depth
  'P TH S', # depths
  'R B', # curb
  'R B D', # curbed
  'R B Z', # curbs
  'R CH T', # arched
  'R CH', # arch
  'R D', # beard
  'R D Z', # beards
  'R DH Z', # berths
  'R F', # scarf
  'R F S', # scarfs
  'R F T', # scarfed
  'R G', # morgue
  # 'R G D', # morgued? theoretically possible, but doesn't occur
  'R G Z', # morgues
  'R JH', # merge
  'R JH D', # merged
  'R K', # mark
  'R K T', # marked
  'R K S', # marks
  'R L D', # world
  'R L D Z', # worlds
  'R L', # curl
  'R L Z', # curls
  'R M', # storm
  'R M D', # stormed
  'R M TH', # warmth
  # 'R M TH S', # warmths? theoretically possible, but doesn't occur
  'R M Z', # storms
  'R N', # earn
  'R N D', # earned
  'R N T', # burnt
  'R N Z', # burns
  'R P', # harp
  'R P S', # harps
  'R P T', # excerpt
  'R P T S', # excerpts
  'R S', # force
  'R S T', # forced
  'R S T S', # bursts
  'R SH', # marsh
  'R SH T', # borscht
  'R T', # part
  'R T S', # parts
  'R TH', # north
  'R TH S', # births
  'R TH T', # unearthed, rare
  'R V', # curve
  'R V D', # curved
  'R V Z', # curves
  'R Z', # furs
  'S K', # mask
  'S K S', # masks
  'S K T', # masked
  'S P', # clasp
  'S P S', # clasps
  'S P T', # clasped
  'S T', # chest
  'S T S', # chests
  'SH T', # mashed
  'T S', # eats
  'T S T', # blitzed
  'TH S', # breaths
  'TH T', # bequeathed
  'V D', # caved
  'V Z', # drives
  'Z D', # dozed
  'ZH D', # camouflaged
] # ARPABET format. source: John Algeo, https://www.tandfonline.com/doi/pdf/10.1080/00437956.1978.11435661 + original work

# Words with weird initial/final consonant clusters that should be included anyway
WHITELIST = [
  'dvorak',
  'neuroscience',
  'neuroscientist',
  'nyet',
  'sbarro',
  'schneider',
  'svelte',
  'tsetse',
  'tsunami',
  'vlad',
  'vladimir',
  'vroom',
  'voila',
  'zloty',
  'zlotys',
]

#
# file utilities
#

def load_string_hash(filename)
  # each line is of the form:
  # KEY  STRING1 STRING2 ...
  # substitutes "_" with " " in keys after loading
  hash = Hash.new {|h,k| h[k] = [] } # hash of strings
  IO.readlines(filename).each{ |line|
    if(useful_line?(line))
      tokens = line.split
      key = tokens.shift # now TOKENS contains only the value strings
      key = desanitize_string(key)
      hash[key] = tokens.map{ |str| desanitize_string(str)}
    else
      debug "Ignoring #{filename} line: #{line}"
    end
  }
  debug "Loaded #{hash.length} entries from #{filename}"
  return hash
end

def sanitize_string (str)
  # sanitizes STR so it can be saved in a space-delimited text file
  return str.gsub(" ", "_")
end

def desanitize_string (str)
  # desanitizes STR. The result may contain spaces.
  return str.gsub("_", " ")
end

def save_string_hash(hash, filename, header="")
  # sanitizes spaces into underscores
  @fh=File.open(filename, 'w')
  unless header.empty?
    @fh.puts(header)
  end
  hash.each do |key, values|
    key = sanitize_string(key)
    @fh.print "#{key} "
    for value in values do
      value = sanitize_string(value)
      @fh.print " #{value}"
    end
    @fh.puts
  end
end

def useful_line?(line)
  # ignore entries that start with ; or #
  return !(line =~ /\A;/ || line =~ /\A#/)
end

#
# rhyme signature
#

def rhyme_signature_array(pron)
  # The rhyme signature is everything including and after the final most stressed vowel,
  # which is indicated in cmudict by a "1".
  # Some words don't have a 1, so we settle for the final secondarily-stressed vowel,
  # or failing that, the last vowel.
  #
  # input: [IH0 N S IH1 ZH AH0 N] # the pronunciation of 'incision'
  # output:        [IH  ZH AH  N] # the pronunciation of '-ision' with stress markers removed
  #
  # We remove the stress markers so that we can rhyme 'furs' [F ER1 Z] with 'yours(2)' [Y ER0 Z]
  # They will both have the rhyme signature [ER Z].
  return rhyme_signature_array_with_stress(pron, "1") || rhyme_signature_array_with_stress(pron, "2") || rhyme_signature_array_with_stress(pron, "0") || error(pron)
end

def rhyme_signature_array_with_stress(pron, stress)
  rsig = Array.new
  pron.reverse.each { |phoneme|
    unless(syllable_boundary?(phoneme))
      rsig.unshift(phoneme.tr("0-2", "")) # we need to remove the numbers
      if(phoneme.include?(stress))
        return rsig # we found the phoneme with stress STRESS, we can stop now
      end
    end
  }
  return nil
end

def initial_consonant_cluster_array(pron)
  # everything strictly before the first vowel
  rsig = Array.new
  pron.each { |phoneme|
    if(vowel?(phoneme))
      return rsig
    else
      rsig.push(phoneme)
    end
  }
  return [ ]
end

def final_consonant_cluster_array(pron)
  # everything strictly after the last vowel
  rsig = Array.new
  pron.reverse.each { |phoneme|
    if(vowel?(phoneme))
      return rsig
    else
      rsig.unshift(phoneme)
    end
  }
  return [ ]
end

def rhyme_signature(pron)
  # this makes for a better hash key
  return rhyme_signature_array(pron).join(" ")
end

def rhyme_syllables_array(pron)
  # This is like rhyme_signature_array but includes the whole rhyming syllable; it doesn't chop off the preceding consonants.
  return rhyme_syllables_array_with_stress(pron, "1") || rhyme_syllables_array_with_stress(pron, "2") || rhyme_syllables_array_with_stress(pron, "0") || error(pron)
end

def rhyme_syllables_array_with_stress(pron, stress)
  rsig = Array.new
  foundTheRhymingSyllable = false
  pron.reverse.each { |phoneme|
    unless syllable_boundary?(phoneme)
      rsig.unshift(phoneme.tr("0-2", "")) # we need to remove the numbers
    end
    if(!foundTheRhymingSyllable)
      if(phoneme.include?(stress))
        foundTheRhymingSyllable = true; # we found the main stressed vowel, we can stop at the next syllable boundary
      end
    else
      if(syllable_boundary?(phoneme))
        return rsig
      end
    end
  }
  if foundTheRhymingSyllable # we got all the way to the beginning of the word without a syllable break
    return rsig
  end
  return nil
end

def vowel?(phoneme)
  return phoneme.include?("1") || phoneme.include?("2") || phoneme.include?("0")
end

def syllable_boundary?(phoneme)
  return phoneme == "."
end

def rhyme_syllables_string(pron)
  # this makes for a better hash key
  return rhyme_syllables_array(pron).join(" ")
end

def lang(lang, en_string, es_string)
  case lang
  when "en"
    return en_string
  when "es"
    return es_string
  else
    abort "Unexpected language #{lang}"
  end
end

def syllabify(pron)
  syls = Array.new
  this_syllable = Array.new
  this_initial_consonant_cluster = Array.new
  candidate_initial_consonant_cluster = Array.new
  foundThisSyllablesVowel = false
  pron.reverse.each { |phoneme|
    if !foundThisSyllablesVowel
      this_syllable.unshift(phoneme) # just allow any syllable-final consonant cluster
      if(vowel?(phoneme))
        foundThisSyllablesVowel = true
      end
    else
      # gobble up as many syllable-initial consonants while still being a valid cluster
      candidate_initial_consonant_cluster = this_initial_consonant_cluster.unshift(phoneme)
      if single_consonant?(candidate_initial_consonant_cluster) ||
         ALL_INITIAL_CONSONANT_CLUSTERS.include?(candidate_initial_consonant_cluster.join(" "))
        this_syllable.unshift(phoneme) # PHONEME is legit as a syllable-initial consonant cluster
        this_initial_consonant_cluster = candidate_initial_consonant_cluster
        # puts "#{phoneme} is legit, now we have #{this_syllable} starting with #{this_initial_consonant_cluster}"
      else
        # that's all we can gobble, gotta move on to the next syllable now
        # puts "we've got #{this_syllable}. That's all we can gobble, gotta move on to the next syllable now"
        syls.unshift(this_syllable)
        # add a syllable boundary token
        syls.unshift(".")
        # ok, stick this phoneme at the end of the next syllable (previous, because we're going backward)
        this_syllable = Array.new
        this_initial_consonant_cluster = Array.new
        this_syllable.unshift(phoneme)
        foundThisSyllablesVowel = vowel?(phoneme)
      end
    end
  }
  # tack on whatever was left over when we ran out of phonemes
  unless this_syllable.empty?
    syls.unshift(this_syllable)
  end
  return syls
end

def single_consonant?(phoneme_cluster)
  return phoneme_cluster.length == 1 && !vowel?(phoneme_cluster[0])
end

# rhyme-ninja
Find semantically related rhymes

## Project Status

No longer under active development by its original creator, Pace Smith. Feel free to branch, fork, whatever you wish!

Also, you can just use the dictionaries without the Ruby code. cmudict 0.7c (my forked version) has several improvements over 0.7b. And there's a rhyming dictionary text file that you're free to use under the GPL.

## Installation

* First install the required packages, such as wordnet and rwordnet. Sorry I didn't package this into a nice gem, feel free to do so.
* Run rspec from the install directory to verify installation. All tests should pass.

## Command Line Usage

echo "word1=food" | rhyme.rb

You can change OUTPUT_TYPE from 'cgi' to 'text' if you want to use it at the command line.

## Webserver Installation

* put everything into your cgi-bin directory
* configure your webserver to allow Ruby scripts
* cd /<whatever>/cgi-bin/
* chmod +x *.rb
* cd dict
* ./dict.rb

That will build the internal dictionaries. Then you ought to be able to go to cgi-bin/rhyme.rb and it will bring up the web interface.

## Examples:

**RHYME NINJA**  
Pairs of rhyming words where the first word is related to **crime** and the second word is related to **heaven**:  
assassination / salvation  
case / airspace  
criminality / immortality  
criminalization / salvation  
fraud / god  
sin / tin  
victimization / salvation  
violation / salvation  

**RHYME NINJA**  
Rhyming word sets that are related to **animal**:  
bitten / kitten  
cetacean / coloration / communication / conservation / domestication / experimentation / inoculation / liberation / predation / respiration / vaccination / vegetation  
claws / jaws / paws  
fauna / iguana  
otter / slaughter  

## How it works

### Building the Rhyming Dictionary

First, run dict/dict.rb offline to compile the rhyming dictionary.
It starts from cmudict, which has a bunch of lines like this:

  KITTEN  K IH1 T AH0 N  
  KITTENS  K IH1 T AH0 N Z  
  KITTERMAN  K IH1 T ER0 M AH0 N  

This will preprocess the cmudict data into a format that's efficient for looking up rhyming words.

We use a two-step lookup process to avoid storing lots of redundant data, e.g. all 500+ "-ation" rhymes as values for "elation", "consternation", etc.

#### Step 1: Given a word, use the CMU Pronouncing Data to get its pronunciation. 

#### Step 1.1: Tweak the given pronunciation to deal with quirks of cmudict. 
e.g. 
curry [K AH1 R IY0] / hurry [HH ER1 IY0]  
ear [IY R] / beer [B IH R]  
        caught [K AA1 T] / fought [F AO1 T]  
        bong [B AA1 NG] / song [S AO1 NG]  
but NOT bar [B AA1 R] / score [S K AO1 R], so we leave it alone if it's followed by R  
If we had reliable data to distinguish 'cot' from 'caught', this would be in imperfect rhymes. But since caught and fought need to rhyme, we're forced to conflate them globally.

illicit [IH2 L IH1 S AH0 T] solicit [S AH0 L IH1 S IH0 T]  
conflate all unstressed schwa-ish syllables, unless they are followed by R or NG.  
mumble a little mumblier, please  

#### Step 1.5: Get the word's rhyme signature

The rhyme signature is everything including and after the final most stressed vowel,
which is indicated in cmudict by a "1".

Some words don't have a 1, so we settle for the final secondarily-stressed vowel,
or failing that, the last vowel.

input: [IH0 N S IH1 ZH AH0 N] # the pronunciation of 'incision'  
output:        [IH  ZH AH  N] # the pronunciation of '-ision' with stress markers removed  

We remove the stress markers so that we can rhyme 'furs' [F ER1 Z] with 'yours(2)' [Y ER0 Z]
They will both have the rhyme signature [ER Z].

#### Step 2: Given the rhyme signature, look up all words that rhyme with it (including itself)

#### Step 2.5: Filter out bad rhymes, like the word itself and subwords (e.g. important rhyming with unimportant)

### Filtering out rare words

When you enter e.g. 'kitten', you'll get back some reasonable
things like 'bitten', 'britain', and 'smitten', but you'll also
get back crap like 'bitton', 'brittain', 'brittan', 'brittin',
'britton', 'ditton', 'fitton', etc.

Some of these are rare words, and some are just
mistakes. Regardless, we don't want them in our output. They
clutter up the place and make the good rhymes harder to see.

We don't want to get rid of them entirely, though; occasionally
that rare word is exactly the one you want, or a good word gets
misfiled as rare. So instead we put them in the 'dregs' bucket,
which shows up as "For the desperate:" on the website.

we use lemma_en and WordNet for word frequency data,
to distinguish rare words from common words.
lemma_en has better coverage than WordNet,
but also includes some false positives.

Also we filter out slurs.

### Semantic Relatedness

Currently, Rhyme Ninja outsources its semantic relatedness to the Datamuse API.

### Putting it all together

When you enter a single word, Rhyme Ninja displays rhymes for that word (separating out the rare words, where rarity is computed as described above) and in a separate column, displays sets of rhyming words. The sets of rhyming words are computed as follows:

Compute the set of all words semantically related to INPUT_REL1, call it RELATEDS1.  
For each word REL1 in RELATEDS1,  
  Get all rhymes RHYME1 of REL1.  
  If R is in RELATEDS1, compute R's rhyme signature RSIG and put RHYME1 in the bucket labeled RSIG.  
Return all buckets with two or more words in them.  

When you enter two words, Rhyme Ninja first displays rhymes for WORD1 that are semantically related to WORD2,  
and in a separate column, displays pairs of rhyming words (RHYME1 / RHYME2) in which RHYME1 is related to WORD1 and RHYME2 is related to WORD2. 

Algorithm:  
Compute the set of all words semantically related to INPUT_REL1, call it RELATEDS1.  
Compute the set of all words semantically related to INPUT_REL2, call it RELATEDS2.  
For each word REL1 in RELATEDS1,  
  Get all rhymes RHYME of REL1.  
  If RHYME rhymes with REL1 and is related to INPUT_REL2, we win! "REL1 / RHYME" is a pair.  

class McSlap
  VERBS = %w[
    slaps hits pricks slays pummeles kills tortures spleefs embiggens ethos
    comparates lags shoves spams withers spanks fracks decorates feeds licks
    inverts smurfs stylizes attacks infects disappears krees
  ].freeze

  ADJECTIVES = [
    'a large', 'an enormous', 'a small', 'a medium sized', 'an extra large',
    'a questionable', 'a suspicious', 'a terrifying', 'a scary',
    'a breath taking', 'a horrifying', 'a glitchy', 'a pixelated',
    'a cromulent', 'a semi-weird', 'a laggy', 'an auspicious',
    'a fracking', 'a manly', 'an undercooked', 'an amazing', 'an upside-down',
    'a smurfy', 'a spiffy', 'an uncaring', 'a deadly', 'a magical', 'a mighty'
  ].freeze

  NOUNS = [
    'piece of cobble', 'redstone repeater set to four', 'brick',
    'brown wool block', 'wooden axe', 'diamond shovel', 'mossy stone brick',
    'cooked fish', 'debonair potion', 'iron ingot', 'dead shrub',
    'birch-wood slab', 'ghast tear', 'jungle tree sapling', 'mellohi disc',
    'end portal frame', 'bottle-o-enchanting', 'cluster of nether wart',
    'picture of Markus Persson', 'used saddle', 'rusty iron hoe',
    'brewing stand', 'rolled up map', 'fermented spider eye',
    'glistering melon', 'ripe cocoa plant', 'pair of shears',
    'stack of rotten flesh', 'dragon egg',
    'enchanted golden sword with fire aspect and knock-back II',
    'primed TNT block', 'brown mushroom', 'ice block', 'FIRE',
    'rubber chicken with a pulley in the middle', 'popsic', 'baby mooshroom',
    'pig spawner', 'book entitled Haircare by jeb', 'Zistonian Battle Sign',
    'cookie stolen from Gamechap, I say',
    'hunk of pork extracted from Granny_Bacon', 'wig of Minecraft Chick',
    'beat up hopper', 'carrot on a stick', 'very damaged anvil', 'lag',
    'unpowered redstone block', 'command block named Cave Johnson',
    'popcorn container', 'frack', 'set of antlers', 'poisoned potato',
    'horse of a different color', 'dinner bone', 'smurf', 'marklar',
    'badass honey badger', 'neurotoxin', 'can of beans', 'jaffa'
  ].freeze

  def self.slap(player, random: Random)
    "#{VERBS.sample(random: random)} #{player} with " \
      "#{ADJECTIVES.sample(random: random)} #{NOUNS.sample(random: random)}"
  end

  def self.combinations
    VERBS.length * ADJECTIVES.length * NOUNS.length
  end
end

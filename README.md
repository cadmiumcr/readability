# Cadmium::Readability

Analyze blocks of text and determine, using various algorithms, the readability of the text.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     cadmium_readability:
       github: cadmiumcr/readability
   ```

2. Run `shards install`

## Usage

```crystal
require "cadmium_readability"

text = <<-EOF
    After marriage, the next big event in the couples lives will be their honeymoon. It is a time when the newly weds can get away from relatives and friends to spend some significant time getting to know one another. This time alone together that the couple shares is called the honeymoon. A great gift idea for the married couple would be to give them a surprise tour package. Most women would like to go on a honeymoon.
    The week or two before the ceremonies would be the best time to schedule a tour because then the budget for this event could be considered. In winter there are more opportunities for the couple to get close to one another because of the cold weather. It is easier to snuggle when the weather is not favorable to outdoor activities. This would afford the couple ample time to know more about themselves during the honeymoon.
    Honeymoon plans should be discussed with the wife to ensure that the shock is pleasant and not a negative experience to her. It is also a good idea in this case, to ask her probing questions as to where she would like to go. Perhaps you could get a friend or family member to ask her what would be her favorite travel location. That would ensure that you know just what she is looking for.
    Make sure that the trip is exactly what she wants. Then on the wedding night tell her about the adventure so that the needed accommodations can be made.
EOF

report = Cadmium::Readability.report.new(text)

puts report.grade_levels.flesch  # => 71.47176470588238
puts report.grade_levels.gunning_fog     # => 10.721568627450981
puts report.grade_levels.kincaid # => 7.513725490196077
```

## Contributing

1. Fork it (<https://github.com/cadmiumcr/cadmium_readability/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Chris Watson](https://github.com/cadmiumcr) - creator and maintainer
- [Rémy Marronnier](https://github.com/cadmiumcr) - core contributor

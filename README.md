![grants_badge](./grants_badge.png)

# scale.rb

**Ruby SCALE Codec Library and Substrate Json-rpc Api Client.**

SCALE is a lightweight, efficient, binary serialization and deserialization codec used by substrate. Most of the input and output data of the substrate API are encoded in SCALE data format. 

This is a SCALE codec library and substrate json-rpc api client implemented in ruby language for general use. It contains the implementation of low-level data formats, various substrate types, metadata support and json-rpc client.

This work is the prerequisite of our subsequent series of projects. We hope to familiarize and quickly access Polkadot and Substrate through ruby. We plan to develop the back end of our applications in ruby language, and then interact with nodes or synchronize data through this library.

Please refer to the [official doc](https://substrate.dev/docs/en/overview/low-level-data-format) for more details about SCALE low-level data format.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'scale.rb'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install scale

## Usage

1. decode

```ruby
require "scale"

# decode a compact integer
scale_bytes = Scale::Bytes.new("0x1501") # create scale_bytes object from scale encoded hex string
o = Scale::Types::Compact.decode scale_bytes # use scale type to decode scale_bytes object
p o.value # 69
```

2. encode

```ruby
require "scale"

o = Scale::Types::Compact.new(69)
p o.encode # "1501"
```
Please go to spec dir for more examples.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/itering/scale.rb.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

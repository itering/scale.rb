![grants_badge](./grants_badge.png)

# scale.rb

**Ruby SCALE Codec Library**

SCALE is a lightweight, efficient, binary serialization and deserialization codec used by substrate. Most of the input and output data of the substrate API are encoded in SCALE data format. 

This is a SCALE codec library implemented in ruby language for general use. It contains the implementation of low-level data formats, various substrate types, metadata support.

This work is the prerequisite of our subsequent series of projects. We hope to familiarize and quickly access Polkadot and Substrate through ruby. We plan to develop the back end of our applications in ruby language, and then interact with nodes or synchronize data through this library.

Please refer to the [official doc](https://substrate.dev/docs/en/knowledgebase/advanced/codec) for more details about SCALE low-level data format.

Because the feature of ruby 2.6 is used, the ruby version is required to be >= 2.6. it will be compatible with older ruby versions when released.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'scale.rb', '0.2.16'
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
o = Scale::Types::Compact.decode(scale_bytes) # use scale type to decode scale_bytes object
p o.value # 69

#
type = Scale::Types::get("Vec<U8>")
o = type.decode(Scale::Bytes.new("0x080001"))
assert_eq o.value, [Scale::Types::U8.new(0), Scale::Types::U8.new(1)]
```

2. encode

```ruby
require "scale"

o = Scale::Types::Compact.new(69)
p o.encode # "1501"

type = Scale::Types::get("Vec<U8>")
o = type.new([Scale::Types::U8.new(0), Scale::Types::U8.new(1)])
p o.encode # "080001"
```
Please go to `spec` dir for more examples.

## Command line tools

After install scale.rb gem, there is a command named `scale` available. You can use it directly in your terminal.

```bash
> scale
Commands:
  scale decode TYPE_NAME HEX SPEC_NAME SPEC_VERSION  # decode HEX string using TYPE_NAME
  scale help [COMMAND]                               # Describe available commands or one specific command
  scale specs                                        # list all chain specs
  scale type TYPE_NAME SPEC_NAME SPEC_VERSION        # show type's ruby class
  scale types SPEC_NAME SPEC_VERSION                 # list all types implemented for chain
```

examples in `exec/scale`

## Running tests

1. Download or clone the code to local, and enter the code root directory
2. If rust is installed on your system (for instance, `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`), call `make` to build the FFI library
3. Run all tests

```
rspec
```

To run single test file:

```bash
rspec spec/types_spec.rb
rspec spec/extrinsic_spec.rb
rspec spec/metadata_spec.rb
rspec spec/types_ffi_spec.rb
```


## Docker

1. update to latest image

   `docker pull itering/scale:latest`

2. Run image:

   `docker run -it itering/scale:latest`

   This  will enter the container with a linux shell opened. 

   ```shell
   /usr/src/app # 
   ```

3. Type `rspec` to run all tests

   ```shell
   /usr/src/app # rspec
   ...................
   
   Finished in 0.00883 seconds (files took 0.09656 seconds to load)
   19 examples, 0 failures
   ```

4. Or, type `./bin/console` to enter the ruby interactive environment and run any decode or encode code

   ```shell
   /usr/src/app # ./bin/console
   [1] pry(main)> scale_bytes = Scale::Bytes.new("0x1501")
   => #<Scale::Bytes:0x000055daa883ba70 @bytes=[21, 1], @data="0x1501", @offset=0>
   [2] pry(main)> o = Scale::Types::Compact.decode(scale_bytes)
   => #<Scale::Types::Compact:0x000055daa89b0db0 @value=69>
   [3] pry(main)> p o.value
   69
   => 69
   [4] pry(main)>
   ```

5. Or, run command line tool:

   ```shell
   /usr/src/app # scale types kusama
   HeadData => Scale::Types::HeadData
   Conviction => Scale::Types::Conviction
   EraRewards => Scale::Types::EraRewards
   ...
   
   Count: 303
   ```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/itering/scale.rb.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

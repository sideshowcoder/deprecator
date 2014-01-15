# Deprecator

Deprecator allows the versioning for Objects, and associating certain actions
with the different versions loaded. This allows for Objects representing Data
allow for Dataupgrades to happen in case the implicit Datamodel changed.

```ruby
class Example
  def initialize version
    @version = version
  end

  attr_accessor :version

  include Deprecator::Versioning
  ensure_version 2, :upgrade_to

  def upgrade_to expected_version
    @version = expected_version
    save
  end

  def save
    # time to save the upgraded object
  end
end

assert Example.new(1).version == 2, "version upgrade failed"
```

This will ensure that whenever an instance of ```Thing``` is initialized the
version will be checked to be 2 or higher. If this is not the case the
```upgrade_to``` function will be called, to handle the version missmatch.
This would be the simplest way to handle versioning with Deprecator.

## Readme first
Deprecator is developed by first writing up the usage and implementing
afterwards, so not everything in the Readme is working. If something is not
working it is marked via ```xruby```. All examples are executable by running

    $ rake test:codesamples

## Installation
Add this line to your application's Gemfile:

    gem 'deprecator'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install deprecator


## Usage

## Limitation
Make sure to define the initializer before including Deprecator::Versioning
since it hooks the initializer, which is not possible if it is overwritten
afterwards.

### Ensure Version
Make sure the version attribute of the object matches at least the given number

```ruby
class Example
  def initialize version
    @version = version
  end

  attr_accessor :version

  include Deprecator::Versioning
  ensure_version 2, :upgrade_to

  def upgrade_to expected_version
    # upgrade code goes here
    @version = expected_version
  end
end

assert Example.new(1).version == 2, "version upgrade failed"
```

### Exact Version

Version attribute has to match the given number exactly, any lower or higher
will result in the missmatch function to be called

```ruby
class Example
  def initialize version
    @version = version
  end

  attr_accessor :version

  include Deprecator::Versioning
  match_version 2, :missmatch

  def missmatch expected_version
    # handle the missmatch
    @version = expected_version
  end
end

assert Example.new(3).version == 2, "version matching failed"
```

### Version property
The object attribute to be used as a version, this defaults to object.version
but can be any other property or a combination by using a lambda or function

```xruby
class Example
  def initialize version
    @my_version = version
  end
  include Deprecator::Versioning

  version_by :incremented_version

  ensure_version 10, :upgrade_to

  def incremented_version
    puts "custom version function called"
    my_version + 3
  end

  def upgrade_to expected
  end
end

Example.new(1)
```

### Global Missmatch Hook
Whenever a missmatch triggers any callback this hook is called as well, this is
great for logging and development but be carefull this can result in a lot of
calls.

```xruby
Deprecator.register_missmatch_hook :version_missmatch

def version_missmatch object, current, expected
  puts "Global missmatch hook triggered version #{current}, expected #{expected}"
end

Example.new(1)
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

# Deprecator

Deprecator allows the versioning for Objects, and associating certain actions
with the different versions loaded. This allows for Objects representing Data
allow for Dataupgrades to happen in case the implicit Datamodel changed.

```ruby
class ExampleOne
  def initialize version
    @version = version
  end

  attr_accessor :version

  include Deprecator::Versioning
  ensure_version 2, :upgrade_to

  def upgrade_to expected_version
    puts "current version #{version} expected #{expected_version} upgrading..."
    @version = expected_version
    save
  end

  def save
    puts "saving new version #{version}"
  end
end

ExampleOne.new(1)
```

This will ensure that whenever an instance of ```Thing``` is initialized the
version will be checked to be 2 or higher. If this is not the case the
```upgrade_to``` function will be called, to handle the version missmatch.
This would be the simplest way to handle versioning with Deprecator.

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
class ExampleTwo
  def initialize version
    @version = version
  end

  attr_accessor :version

  include Deprecator::Versioning
  ensure_version 2, :upgrade_to

  def upgrade_to expected_version
    # upgrade code goes here
    puts "upgrading from #{version} to #{expected_version}"
  end
end

ExampleTwo.new(1)
```

### Exact Version

Version attribute has to match the given number exactly, any lower or higher
will result in the missmatch function to be called

```xruby
class Thing
  include Deprecator::Versioning

  attr_accessor :version

  exact_match_version 2, :missmatch

  def missmatch expected_version
    # handle the missmatch
    self.version = expected_version
    self.save
  end

  def save
    # store back in database
  end
end
```

### Global Missmatch Hook

Whenever a missmatch happens the hook is called, but be carefull this can
result in a lot of calls.

```xruby
Deprecator.register_missmatch_hook :version_missmatch

def version_missmatch object, current, expected
  puts "Version for #{object.name} was expected to be #{expected} but was
  #{current}"
end
```

### Version property

The object attribute to be used as a version, this defaults to object.version
but can be any other property or a combination by using a lambda or function

```xruby
class Thing
  include Deprecator::Versioning

  version_by :incremented_version

  def incremented_version
    my_version + 3
  end
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Pollbooth [![Build Status](https://travis-ci.org/crowdtap/pollbooth.png?branch=master)](https://travis-ci.org/crowdtap/pollbooth)
======

Pollbooth is an easy way to cache data that is automatically refreshed at a regular interval.

Install
-------

```ruby
gem install pollbooth
```
or add the following line to your Gemfile:
```ruby
gem 'pollbooth'
```
and run `bundle install`

Usage
-----

```ruby
  class MemberCache
    include PollBooth

    cache 10.seconds do
      Hash[Member.all.map { |member| [member.id, member.age] }]
    end
  end
```

This will cache the age attribue using the member id as the key. So
`MemberCache.lookup('jon@example.com')` will return the age of the member with
email address `jon@example.com`.

The poller will start lazily on the first lookup but you can also start it
manually. This is recommended if populating the cache is expensive and will
compromise the first request. You should do this in the `after_fork` block if 
you are using unicorn. Otherwise you can do it in an initializer.

```ruby
  MemberCache.start
```


License
-------
Copyright (C) 2013 Crowdtap

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

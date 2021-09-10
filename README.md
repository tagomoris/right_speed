# RightSpeed

RightSpeed is **an experimental application server** to host Rack applications, on Ractor workers, to test/verify that your application is Ractor-safe/Ractor-ready or not.
Ractor is an experimental feature of Ruby 3.0, thus **this application server is also not for production environments**.

Currently, RightSpeed supports the very limited set of Rack protocol specifications. Unsupported features are, for example:

* Writing logs into files
* Daemonizing processes
* Reloading applications without downtime
* Handling session objects (using `rack.session`)
* Handling multipart contents flexisbly (using `rack.multipart.buffer_size` nor `rack.multipart.tempfile_factory`)
* [Hijacking](https://github.com/rack/rack/blob/master/SPEC.rdoc#label-Hijacking)

### Is Ractor-based server faster than prefork processes?

It can be. In our opinion, it may not be a tremendous difference, but could be a little improvement because:
* Accepted connection delivery inter-Ractor should be faster than bringing those over IPC
* JIT compilation can be just once using multiple Ractor
* ... and?

## Changelog

* v0.2.0:
  * Add worker-type "fair" and "accept" in addition to "roundrobin"
* v0.1.0:
  * The first release just before RubyKaigi Takeout 2021

## Usage

Use the latest Ruby 3.x release!

Install `right_speed` by `gem` command (`gem i right_speed`), then use it directly:

```
$ right_speed -c config.ru -p 8080 --workers 8

$ right_speed --help
Usage: right_speed [options]

OPTIONS
  --config, -c PATH     The path of the rackup configuration file (default: config.ru)
  --port, -p PORT       The port number to listen (default: 8080)
  --backlog NUM         The number of backlog
  --workers NUM         The number of Ractors (default: CPU cores)
  --worker-type TYPE    The type of workers (available: roundrobin/fair/accept, default: roundrobin)
  --help                Show this message
```

Or, use `rackup` with `-s right_speed`:

```
$ rackup config.ru -s right_speed -p 8080 -O Workers=8
```

The default number of worker Ractors is the number of CPU cores.

### Worker Types

The `--worker-type` option is to try some patterns of use of Ractors.

* `roundrobin`
  * Listener Ractor will accept connections, then send those to Worker Ractors in round-robin
  * Worker Ractors will consume their input connections one-by-one
* `fair`
  * Listener Ractor will accept connections, and yield those to consumers (workers)
  * Worker Ractors will take connections from Listener as soon as they become available
* `accept`
  * Listener does nothing
  * Worker Ractors will accept connections, process requests individually

Currently, any of above workers cannot work well. We observed SEGV or Ruby runtime busy after traffic in seconds.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tagomoris/right_speed.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

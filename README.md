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

## Usage

Use the latest Ruby 3.x release!

Install `right_speed` by `gem` command (`gem i right_speed`), then use it directly:

```
$ right_speed -c config.ru -p 8080 --workers 8

# See right_speed --help for full options:
$ right_speed --help
Usage: right_speed [options]

OPTIONS
  --config, -c PATH     The path of the rackup configuration file (default: config.ru)
  --port, -p PORT       The port number to listen (default: 8080)
  --backlog NUM         The number of backlog
  --workers NUM         The number of Ractors (default: CPU cores)
  --worker-type TYPE    The type of workers, available options are read/accept (default: read)
  --help                Show this message
```

Or, use `rackup` with `-s right_speed`:

```
$ rackup config.ru -s right_speed -p 8080 -O Workers=8
```

The default number of worker Ractors is the number of CPU cores.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tagomoris/right_speed.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

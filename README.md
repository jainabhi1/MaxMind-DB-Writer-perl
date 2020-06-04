# NAME

MaxMind::DB::Writer - Create MaxMind DB database files

# VERSION

version 0.300003

# SYNOPSIS

    use MaxMind::DB::Writer::Tree;

    my %types = (
        color => 'utf8_string',
        dogs  => [ 'array', 'utf8_string' ],
        size  => 'uint16',
    );

    my $tree = MaxMind::DB::Writer::Tree->new(
        ip_version            => 6,
        record_size           => 24,
        database_type         => 'My-IP-Data',
        languages             => ['en'],
        description           => { en => 'My database of IP data' },
        map_key_type_callback => sub { $types{ $_[0] } },
    );

    $tree->insert_network(
        '8.8.8.0/24',
        {
            color => 'blue',
            dogs  => [ 'Fido', 'Ms. Pretty Paws' ],
            size  => 42,
        },
    );

    open my $fh, '>:raw', '/path/to/my-ip-data.mmdb';
    $tree->write_tree($fh);

# DESCRIPTION

This distribution contains the code necessary to write [MaxMind DB database
files](http://maxmind.github.io/MaxMind-DB/). See [MaxMind::DB::Writer::Tree](https://metacpan.org/pod/MaxMind::DB::Writer::Tree)
for API docs.

# MAC OS X SUPPORT

If you're running into install errors under Mac OS X, you may need to force a
build of the 64 bit binary. For example, if you're installing via `cpanm`:

    ARCHFLAGS="-arch x86_64" cpan MaxMind::DB::Writer

# WINDOWS SUPPORT

This distribution does not currently work on Windows. Reasonable patches for
Windows support are very welcome. You will probably need to start by making
[Math::Int128](https://metacpan.org/pod/Math::Int128) work on Windows, since we use that module's C API for dealing
with 128-bit integers to represent IPv6 addresses numerically.

# SUPPORT

Please report all issues with this code using the GitHub issue tracker at
[https://github.com/maxmind/MaxMind-DB-Writer-perl/issues](https://github.com/maxmind/MaxMind-DB-Writer-perl/issues).

We welcome patches as pull requests against our GitHub repository at
[https://github.com/maxmind/MaxMind-DB-Writer-perl](https://github.com/maxmind/MaxMind-DB-Writer-perl).

Bugs may be submitted through [https://github.com/maxmind/MaxMind-DB-Writer-perl/issues](https://github.com/maxmind/MaxMind-DB-Writer-perl/issues).

# AUTHORS

- Olaf Alders <oalders@maxmind.com>
- Greg Oschwald <goschwald@maxmind.com>
- Dave Rolsky <drolsky@maxmind.com>
- Mark Fowler <mfowler@maxmind.com>

# CONTRIBUTORS

- Florian Ragwitz <rafl@debian.org>
- Ilya Melamed <ilya77@gmail.com>
- Jan Bieron &lt;jbieron+github@gmail.com>
- Narsimham Chelluri <nchelluri@users.noreply.github.com>
- Thomas J Mather <tjmather@maxmind.com>
- William Storey <wstorey@maxmind.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

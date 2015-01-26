use strict;
use warnings;
use utf8;

use lib 't/lib';

use Test::Requires {
    JSON => 0,
};

use Test::MaxMind::DB::Writer qw( make_tree_from_pairs );
use Test::More;

use File::Temp qw( tempdir );
use Math::Int128 qw( uint128 );
use MaxMind::DB::Writer::Tree;
use Net::Works::Network;

# The record size really has nothing to do with the freeze/thaw code, but it
# doesn't really hurt to test this either.
for my $record_size ( 24, 28, 32 ) {
    {
        my $tree = MaxMind::DB::Writer::Tree->new(
            ip_version              => 4,
            record_size             => $record_size,
            database_type           => 'Test',
            languages               => [ 'en', 'fr' ],
            description             => { en => 'Test tree' },
            merge_record_collisions => 1,
            map_key_type_callback   => sub { 'uint32' },
        );

        my $count = 2**8;

        for my $i ( 1 .. $count ) {
            my $ipv4 = Net::Works::Network->new_from_integer(
                integer       => $i,
                prefix_length => $i % 32,
                version       => 4,
            );
            $tree->insert_network( $ipv4, { i => $i } );
        }

        subtest(
            "Tree with $count networks - IPv4 only - $record_size-bit records",
            sub {
                _test_freeze_thaw_for_tree($tree);
            }
        );

        {
            my $cb = sub {
                my $key = $_[0];
                $key =~ s/X$//;
                return $key eq 'array' ? [ 'array', 'uint32' ] : $key;
            };

            my $tree = MaxMind::DB::Writer::Tree->new(
                ip_version              => 6,
                record_size             => 24,
                database_type           => 'Test',
                languages               => ['en'],
                description             => { en => 'Test tree' },
                merge_record_collisions => 1,
                map_key_type_callback   => $cb,
            );

            my $count       = 2**14;
            my $ipv6_offset = uint128(2)**34;

            for my $i ( 1 .. $count ) {
                my $ipv4 = Net::Works::Network->new_from_integer(
                    integer       => $i,
                    prefix_length => 128,
                    version       => 6
                );
                $tree->insert_network( $ipv4, _data_record( $i % 16 ) );

                my $ipv6 = Net::Works::Network->new_from_integer(
                    integer       => $i + $ipv6_offset,
                    prefix_length => 128,
                    version       => 6
                );
                $tree->insert_network( $ipv6, _data_record( $i % 16 ) );
            }

            subtest(
                "Tree with $count networks - mixed IPv4 and IPv6 - $record_size-bit records",
                sub {
                    _test_freeze_thaw_for_tree( $tree, $cb );
                }
            );
        }
    }
}

{
    open my $fh, '<', 't/test-data/geolite2-sample.json';
    my $geolite2_data = do { local $/; <$fh> };
    my $records = JSON->new->decode($geolite2_data);
    close $fh;

    my $tree = make_tree_from_pairs(
        $records,
        {
            root_data_type     => 'utf8_string',
            alias_ipv6_to_ipv4 => 1,
        }
    );

    subtest(
        'Tree made from GeoLite2 sample data',
        sub {
            _test_freeze_thaw_for_tree($tree);
        }
    );
}

sub _test_freeze_thaw_for_tree {
    my $tree1 = shift;

    my $dir = tempdir( CLEANUP => 1 );
    my $file = "$dir/frozen-tree";
    $tree1->freeze_tree($file);

    my $tree2 = MaxMind::DB::Writer::Tree->new_from_frozen_tree(
        filename              => $file,
        map_key_type_callback => $tree1->map_key_type_callback(),
    );

    my $now = time();
    $_->_set_build_epoch($now) for $tree1, $tree2;

    my $tree1_output;
    open my $fh, '>:raw', \$tree1_output;
    $tree1->write_tree($fh);
    close $fh;

    my $tree2_output;
    open $fh, '>:raw', \$tree2_output;
    $tree2->write_tree($fh);
    close $fh;

    ok(
        $tree1_output eq $tree2_output,
        'output for tree is the same after freeze/thaw'
    );

    my @attrs = qw(
        _root_data_type
        alias_ipv6_to_ipv4
        database_type
        description
        ip_version
        languages
        merge_record_collisions
        record_size
    );

    for my $attr (@attrs) {
        is_deeply(
            $tree1->$attr(),
            $tree2->$attr(),
            "$attr remains the same across freeze/thaw"
        );
    }
}

done_testing();

sub _data_record {
    my $i = shift;

    return {
        utf8_string => 'unicode! ☯ - ♫ - ' . $i,
        double      => 42.123456 + $i,
        bytes       => pack( 'N', 42 + $i ),
        uint16      => 100 + $i,
        uint32      => 2**28 + $i,
        int32       => -1 * ( 2**28 + $i ),
        uint64      => ( uint128(1) << 60 ) + $i,
        uint128     => ( uint128(1) << 120 ) + $i,
        array       => [ 1, 2, 3, $i ],
        map         => {
            mapX => {
                utf8_stringX => 'hello - ' . $i,
                arrayX       => [ 7, 8, 9, $i ],
            },
        },
        boolean => $i % 2,
        float   => 1.1 + $i,
    };
}
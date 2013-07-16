use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;

use MaxMind::DB::Writer::Tree::InMemory;
use Math::Int128 qw( uint128 );
use Net::Works::Network;

{
    my $int128 = uint128(2) << 120;

    my $tree = MaxMind::DB::Writer::Tree::InMemory->new( ip_version => 4 );

    is(
        exception {
            $tree->insert_subnet(
                Net::Works::Network->new_from_string(
                    string => '1.1.1.0/24'
                ),
                { value => $int128 },
            );
        },
        undef,
        'no exception inserting data that includes a Math::UInt128 object'
    );

    is_deeply(
        $tree->lookup_ip_address(
            Net::Works::Address->new_from_string( string => '1.1.1.1' )
        ),
        { value => $int128 },
        'got expected value back with Math::UInt128 object'
    );
}

done_testing();

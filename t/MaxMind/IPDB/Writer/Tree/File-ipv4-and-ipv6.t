use strict;
use warnings;

use Test::More;

use MaxMind::IPDB::Writer::Tree::InMemory;
use MaxMind::IPDB::Writer::Tree::File;

use File::Temp qw( tempdir );
use MaxMind::IPDB::Reader::File;
use MM::Net::Subnet;

my $tempdir = tempdir( CLEANUP => 1 );

{
    my ( $tree, $filename ) = _write_tree();

my $processor = MaxMind::IPDB::Writer::Tree::Processor::VisualizeTree->new(
    ip_version => 6 );
$tree->iterate($processor);

$processor->graph()->run( output_file => '/tmp/aliased.svg' );

    my $reader = MaxMind::IPDB::Reader::File->new( file => $filename );

    my %tests = (
        '1.1.1.1'          => { subnet => '::101:101/128' },
        '::101:101'        => { subnet => '::101:101/128' },
        '1.1.1.2'          => { subnet => '::101:102/127' },
        '::101:102'        => { subnet => '::101:102/127' },
        '1.1.1.3'          => { subnet => '::101:102/127' },
        '255.255.255.2'    => { subnet => '::ffff:ff00/120' },
        '::ffff:ff02'      => { subnet => '::ffff:ff00/120' },
        '::101:103'        => { subnet => '::101:102/127' },
        '::ffff:101:101'   => { subnet => '::101:101/128' },
        '::ffff:101:102'   => { subnet => '::101:102/127' },
        '::ffff:101:103'   => { subnet => '::101:102/127' },
        '::ffff:ffff:ff02' => { subnet => '::ffff:ff00/120' },
        '2002:101:101::'   => { subnet => '::101:101/128' },
        '2002:101:102::'   => { subnet => '::101:102/127' },
        '2002:101:103::'   => { subnet => '::101:102/127' },
        '2002:ffff:ff02::' => { subnet => '::ffff:ff00/120' },
    );

    for my $address ( sort keys %tests ) {
        is_deeply(
            $reader->data_for_address($address),
            $tests{$address},
            "got expected data for $address"
        );
    }
}

done_testing();

sub _write_tree {
    my $tree = MaxMind::IPDB::Writer::Tree::InMemory->new();

    my @subnets = map { MM::Net::Subnet->new( subnet => $_, version => 6 ) }
        qw(
        ::1.1.1.1/128
        ::1.1.1.2/127
        ::255.255.255.0/120
    );

    for my $net (@subnets) {
        $tree->insert_subnet(
            $net,
            { subnet => $net->as_string() },
        );
    }

    my $writer = MaxMind::IPDB::Writer::Tree::File->new(
        tree          => $tree,
        record_size   => 24,
        database_type => 'Test',
        languages     => [ 'en', 'zh' ],
        description   => {
            en => 'Test Database',
            zh => 'Test Database Chinese',
        },
        ip_version            => 6,
        alias_ipv6_to_ipv4    => 1,
        map_key_type_callback => sub { 'utf8_string' },
    );

    my $filename = $tempdir . "/Test-ipv6-alias.mmipdb";
    open my $fh, '>', $filename;

    $writer->write_tree($fh);

    return ( $tree, $filename );
}
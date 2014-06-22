use strict;
use warnings;

use Test::More;

BEGIN { use_ok('Maven::Maven') }

use Data::Dumper;
use File::Basename;
use File::Spec;

my $test_dir = dirname( File::Spec->rel2abs( $0 ) );
my $maven;

$maven = Maven::Maven->new( 
    M2_HOME => File::Spec->catdir( $test_dir, 'M2_HOME' ),
    'user.home' => File::Spec->catdir( $test_dir, 'HOME' ) );
print( "REMOVE ME: ", Dumper( $maven ), "\n" );

done_testing();
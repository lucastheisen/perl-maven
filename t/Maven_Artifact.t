use strict;
use warnings;

use Test::More;

BEGIN { use_ok('Maven::Artifact') }

use Maven::Artifact;

my $artifact;

$artifact = Maven::Artifact->new( 'org.apache.maven:maven:pom::3.2.1' );
is( $artifact->get_groupId(), 'org.apache.maven', 'coordinate to groupId' );
is( $artifact->get_artifactId(), 'maven', 'coordinate to artifactId' );
is( $artifact->get_packaging(), 'pom', 'coordinate to packaging' );
is( $artifact->get_classifier(), '', 'coordinate to packaging' );
is( $artifact->get_version(), '3.2.1', 'coordinate to version' );

done_testing();
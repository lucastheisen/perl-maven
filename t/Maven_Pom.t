use strict;
use warnings;

use Test::More;

BEGIN { use_ok('Maven::Pom') }

use Data::Dumper;
use File::Basename;
use File::Spec;
use Maven::Repositories;

my $test_dir = dirname( File::Spec->rel2abs( $0 ) );
my $pom;
my $repositories = Maven::Repositories->new()
    ->add_local( Maven::LocalRepository->new(
        path => File::Spec->catdir( $test_dir, 'HOME', '.m2', 'repository' )
    ) );

$pom = Maven::Pom->new(
    repositories => $repositories,
    groupId => 'com.pastdev',
    artifactId => 'foo',
    version => '1.0.1'
);
print( "REMOVE ME: ", Dumper( $pom ), "\n" );

done_testing();
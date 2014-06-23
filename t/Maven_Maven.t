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

my @active_profiles = map {$_->get_id()} @{$maven->{active_profiles}};
is_deeply( \@active_profiles,
    ['userSettings','globalActiveProfile'],
    'active profiles' );
    
my $user_home = $maven->get_property( 'user.home' );
my $local_repo_url = "file://$user_home/.m2/repository";
my @repositories = map {$_->get_url()} @{$maven->get_repositories()->{repositories}};
is_deeply( \@repositories,
    [
        $local_repo_url,
        'http://maven.pastdev.com/nexus/groups/pastdev',
        'http://repo.maven.apache.org/maven2'
    ],
    'repositories' );

done_testing();
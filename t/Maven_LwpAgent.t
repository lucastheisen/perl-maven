use strict;
use warnings;

use Test::More;

BEGIN { use_ok('Maven::LwpAgent') }

use Digest::MD5;
use File::Basename;
use File::Spec;
use Maven::Maven;

my $test_dir = dirname( File::Spec->rel2abs( $0 ) );
my $maven_central_url = 'http://repo.maven.apache.org/maven2';

sub hash_file {
    my ($file) = @_;
    open(my $handle, '<', $file) || croak("cant open $file: $!");
    binmode($handle);
    my $hash = Digest::MD5->new();
    $hash->addfile($handle);
    close($handle);
    return $hash->hexdigest();
}

SKIP: {
    eval { require LWP::UserAgent };

    skip "LWP::UserAgent not installed", 2 if $@;


    my $lwp = LWP::UserAgent->new();
    $lwp->timeout( 1 );
    $lwp->env_proxy();

    my $agent = Maven::LwpAgent->new(agent => $lwp);

    require Maven::Maven;
    my $maven = Maven::Maven->new( 
        M2_HOME => File::Spec->catdir($test_dir, 'M2_HOME'),
        'user.home' => File::Spec->catdir($test_dir, 'HOME'),
        agent => $agent);

    if ($agent->head($maven_central_url)->is_success()) {
        my $jta_jar = $maven->get_repositories()->resolve('javax.transaction:jta:1.1');
        ok($jta_jar, 'resolve jta jar');

        is($maven->get_repositories()
            ->get_repository($jta_jar->get_url())
            ->get_agent(),
            $agent,
            'agents match');

        my $jta_jar_file = $jta_jar->download(agent => $maven);
        ok($jta_jar_file, 'got jta jar file');
        ok(-s $jta_jar_file, 'jta jar file is not empty');

        my $jta_jar_file_to = $jta_jar->download(agent => $agent, to => File::Temp->new());
        ok($jta_jar_file_to, 'got jta jar to file to');
        ok(-s $jta_jar_file_to, 'jta jar file to is not empty');
        
        is(hash_file($jta_jar_file), hash_file($jta_jar_file_to), 'jta hashes match');
    }
};

done_testing();

use strict;
use warnings;

use Test::More;

BEGIN { use_ok('Maven::MvnAgent') }

use Digest::MD5;
use File::Basename;
use File::Spec;
use File::Temp;
use Log::Any;
use Log::Any::Adapter ('Stdout', log_level => 'debug' );

my $logger = Log::Any->get_logger();
$logger->info( 'logging for Maven_MvnAgent.t' );

my $test_dir = dirname( File::Spec->rel2abs( $0 ) );

my $pastdev_url = 'http://pastdev.com/nexus/groups/pastdev';
my $maven_central_url = 'http://repo.maven.apache.org/maven2';

sub escape_and_quote {
    my ($value) = @_;
    $value =~ s/\\/\\\\/g;
    $value =~ s/"/\\"/g;
    return "\"$value\"";
}

sub hash_file {
    my ($file) = @_;
    open(my $handle, '<', $file) || croak("cant open $file: $!");
    binmode($handle);
    my $hash = Digest::MD5->new();
    $hash->addfile($handle);
    close($handle);
    return $hash->hexdigest();
}

sub os_path {
    my ($path) = @_;
    my $os_path = $^O eq 'cygwin'
        ? Cygwin::posix_to_win_path($path)
        : $path;
}

SKIP: {
    eval { require LWP::UserAgent };

    skip "LWP::UserAgent not installed", 7 if $@;

    my $user_home = File::Spec->catdir($test_dir, 'HOME');
    my $temp_dir = File::Temp->newdir();
    my $mvn_test_user_home = File::Spec->catdir($temp_dir, 'HOME');
    `cp -r $user_home $temp_dir`;
    my $mvn_test_user_settings = File::Spec->catfile($mvn_test_user_home, '.m2', 'settings.xml');
    `mv $mvn_test_user_home/.m2/empty_settings.xml $mvn_test_user_settings`;
    ok((-f $mvn_test_user_settings), "mvn test $mvn_test_user_home/.m2/settings.xml exists");

    my $agent = Maven::MvnAgent->new(
        M2_HOME => File::Spec->catdir($test_dir, 'M2_HOME'),
        'user.home' => $mvn_test_user_home);
    is($agent->get_maven()->dot_m2('settings.xml'), $mvn_test_user_settings, 'user settings');
    my $get_goal = 'org.apache.maven.plugins:maven-dependency-plugin:2.10:get';
    is($agent->get_command('javax.servlet:servlet-api:2.5'),
        "mvn --settings " 
            . escape_and_quote(os_path($mvn_test_user_settings)) 
            . " -Duser.home=" 
            . escape_and_quote(os_path($mvn_test_user_home)) 
            . " $get_goal -DartifactId=\"servlet-api\" -DgroupId=\"javax.servlet\""
            . " -Dpackaging=\"jar\" -DremoteRepositories=\"$maven_central_url\" -Dversion=\"2.5\"",
        'get servlet-api command');

    if ($agent->get_maven()->_default_agent(timeout => 1)->head($maven_central_url)->is_success()) {
        my $jta_jar = $agent->resolve('javax.transaction:jta:1.1');
        ok($jta_jar, 'resolve jta jar');

        SKIP: {
            skip "mvn not installed", 5 if (system('which mvn') >> 8);
            $logger->warn("first mvn call, be patient, lots of downloads");

            my $jta_jar_file = $agent->download($jta_jar);
            ok($jta_jar_file, 'got jta jar file');
            ok(-s $jta_jar_file, 'jta jar file is not empty');

            my $jta_jar_file_to = $agent->download($jta_jar, to => File::Temp->new());
            ok($jta_jar_file_to, 'got jta jar to file to');
            ok(-s $jta_jar_file_to, 'jta jar file to is not empty');
            
            is(hash_file($jta_jar_file), hash_file($jta_jar_file_to), 'jta hashes match');
        }
    }
};

done_testing();

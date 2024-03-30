package lib::root;
use strict;
use warnings;
use Path::Tiny;

our $VERSION = "0.02";

sub import
{
  my ( $package, %args ) = @_;
  my $rootfile    = $args{ rootfile } || '.libroot';
  my $callback    = $args{ callback };
  my $perldir     = $args{ perldir };
  my $caller_file = $args{ caller_file } || Cwd::realpath( ( caller )[ 1 ] );
  my $path        = path( $caller_file )->parent;

  $path = $path->realpath->absolute;
  my $found;
  my $lib_paths;

  my @children = grep { defined } ( $perldir, $rootfile );
  while ( !$found && $path ne $path->rootdir )
  {
    if ( -e $path->child( @children ) )
    {
      $found     = $path->child( @children );
      $lib_paths = $path->child( @children )->parent->child( '/*/lib' );
      last;
    }
    elsif ( -e $path->child( $rootfile )
      && $perldir
      && -d $path->child( $perldir ) )
    {
      $found     = $path->child( $rootfile );
      $lib_paths = $path->child( $perldir, '/*/lib' );
      last;
    }
    $path = $path->parent;

  }

  if ( $found )
  {
    push @INC, glob $lib_paths;
    $callback->( $lib_paths, $found )
      if $callback;
  }
  else
  {
    warn
      "lib::root error: Could not find rootfile [ $rootfile ]. lib::root loaded from [ $caller_file ].";
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

lib::root - find perl root and push lib modules path to @INC

=head1 VERSION

version 0.01

=head1 SYNOPSIS

lib::root looks for a .libroot file on parent directories and pushes ./*/lib to @INC.

When a file does "use lib::root", lib::root will try to read the file parent directories and look for a rootfile (default is .libroot) that is usually located inside a /some/dir/perl that contains many modules used by your app. Many apps have a /some/dir/perl/.perl-version file inside a perl directory, when that is the case, the app can piggy back on that filename and look for that file instead of .libroot with the example below:

  use lib::root rootfile => '.perl-version';

To use the defaults, create an empty file named .libroot and place it in your /app/dir/perl/.libroot

  use lib::root;

  ... or use another custom file to determine a libroot

  use lib::root; # rootfile defaults to .libroot
  use lib::root rootfile => '.perl-version';

  ... or add a callback if needed

  use lib::root callback => sub { ... };

  ... or look for a given file in approot and use a perl root dir to push to inc

  use lib::root rootfile => '.app-root', path => 'perl';

=head1 WHY IS THIS USEFUL

lib::root can be useful when your application perl modules are not installed globally.

When your app uses lib::root, the lib::root will look for the .libroot file into parent directories relative to the file using it.

For example, your app has the following structure:

  /dir/myapp/perl/MyApp-Thing/lib/...
  /dir/myapp/perl/MyApp-Another/lib/...
  /dir/myapp/perl/MyApp-Stuff/lib/...
  /dir/myapp/perl/.perl-version
  /dir/myapp/bin/some_script.pl
  /dir/myapp/bin/another_script.pl
  /dir/myapp/.app-root

... and the app needs to push all those perl/*/lib to @INC. There are some ways to do that

Add the directory to env PERLLIB or PERL5LIB

  PERLLIB=$PERLLIB:/dir/myapp/perl/MyApp-Thing/lib:/dir/myapp/perl/MyApp-Another/lib

Or use -I

  perl -I/dir/myapp/perl/MyApp-Thing/lib -I/dir/myapp/perl/MyApp-Another/lib

Or use a BEGIN block:

  BEGIN { push @INC, glob "/dir/myapp/perl/*/lib"; }

Or use lib::root:

  use lib::root rootfile => '.perl_is_here';

lib::root can also be instructed to look in a cousin dir relative to "bin" in the structure above

  use lib::root path => '../perl';

Or use lib

  use FindBin qw($Bin);
  use lib "$Bin/../lib";
  use lib "/home/user/MyApp/lib";

Or some other way ...

=head2 SEE ALSO

Similar ideas have been implemented before in the modules below and possibly others

=item * RepRoot

L<https://metacpan.org/pod/RepRoot>

=item * lib::glob

L<https://metacpan.org/pod/lib::glob>

=head1 LICENSE

Copyright (C) Hernan Lopes.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hernan Lopes E<lt>hernan@smallcompany.netE<gt>

=cut


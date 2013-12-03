#!/usr/bin/env perl

use 5.010; # for ${^CHILD_ERROR_NATIVE} to get backticks error code

use strict;
use warnings;

use File::Path;
use File::Spec;

=pod USE

A script to help set up autofs on Mac OS X. This script expects to be called with super
user rights:

	sudo ./setup-autofs.pl

*** You will need to modify the code immediately below this comment. ***

Notes:
- Avoid 'name' and 'share' values with spaces and escaping characters. Keep them simple.
- If your password contains non-alphanumeric characters, it will need to be URL encoded.
  Use: http://meyerweb.com/eric/tools/dencoder/
=cut

my @sharepoints = (
	{
		'name' => 'myWindowsPC',
		'static-ip' => '192.168.1.2',
		'share' => 'C',
		'filesystem' => 'smbfs,soft',
		'username' => 'REPLACE-WITH-USER',
		'password' => 'REPLACE-WITH-PASSWORD',
	},
#	{
#		'name' => 'myOtherPC',
#		'static-ip' => '192.168.1.3',
#		'share' => 'C',
#		'filesystem' => 'smbfs,soft',
#		'username' => 'REPLACE-WITH-USER',
#		'password' => 'REPLACE-WITH-PASSWORD',
#	},	
);

=pod

Nothing to configure or change from this line on.

=cut

# Ensure this script is run as root
die("ERROR script requires root user permissions; run again as: 'sudo $0'\n") if ($> != 0);

# Make a directory to mount the volume within
my $mount_path = File::Spec->catdir('/','mnt');
print "* Setting up location to mount volume within...";

if (not -d $mount_path) {
	File::Path::make_path($mount_path) or die('ERROR creating folder path: '.$mount_path.': '.$!);
	print " creating $mount_path, ok\n";
} else {
	print " path '$mount_path' already exists, ok\n";
}

# With the directory available, prepare to add a line to the auto_master file
my $automaster_path = File::Spec->catfile('/','etc','auto_master');
die('ERROR expected configuration file does not exist: '.$automaster_path) unless -e $automaster_path;

# Ensure a copy of the original /etc/auto_master file exists
my $automaster_backup_path = $automaster_path.'.backup';
print "* Ensuring back up of $automaster_path...";

if (not -e $automaster_backup_path) {
	&_do("cp '$automaster_path' '$automaster_backup_path'");
	print " copied to $automaster_backup_path, ok\n";
} else {
	print " already exists, ok\n";
}

# Read in the existing automaster file
open(my $automaster_ro,'<',$automaster_path) or die('ERROR reading: '.$automaster_path.': '.$!);
my $automaster_contents = do { local $/; <$automaster_ro> };
close($automaster_ro) or die('ERROR closing: '.$automaster_path.': '.$!);

# Ensure the mount path is unique
my $auto_mnt_filename = 'auto_mnt';
print "* Setting up mount folder in $automaster_path...";
if ($automaster_contents =~ /^$mount_path\s+(?<path>\S+)/gsm) {
	print " already exists at '".$+{path}."', ok\n";
} else {
	# Add new mount folder; mount path, config file name, no super user id flag
	open(my $automaster_append,'>>',$automaster_path) or die('ERROR append: '.$automaster_path.': '.$!);
	printf($automaster_append "\n%s\t%s\t-nosuid\n",$mount_path,$auto_mnt_filename);
	close($automaster_append) or die('ERROR closing: '.$automaster_path.': '.$!);
	print " appended ok\n";
}

# Create an autofs configuration file for the mount path
my($volume,$directories,undef) = File::Spec->splitpath($automaster_path);
my $sharepoint_path = File::Spec->catpath($volume,$directories,$auto_mnt_filename);
print "* Preparing contents of $sharepoint_path...";
my $sharepoint_contents = '';
foreach my $sharepoint (@sharepoints) {
	$sharepoint_contents .= <<_SHARE;
$sharepoint->{name}	-fstype=$sharepoint->{filesystem}	://$sharepoint->{username}:$sharepoint->{password}\@$sharepoint->{'static-ip'}/$sharepoint->{share}
_SHARE
}
print " ok\n";

# Back up existing configuration file, without overwriting any existing back up
my $sharepoint_backup_path = $sharepoint_path.'.backup';
if ((-e $sharepoint_path) and (not -e $sharepoint_backup_path)) {
	&_do("cp '$sharepoint_path' '$sharepoint_backup_path'");
	print "* Backed up existing configuration to $sharepoint_backup_path, ok\n";
}

# Write configuration to disk
print "* Writing configuration to $sharepoint_path...";
open(my $sharepoint_write,'>',$sharepoint_path) or die('ERROR write: '.$sharepoint_path.': '.$!);
printf($sharepoint_write "%s\n",$sharepoint_contents);
close($sharepoint_write) or die('ERROR closing: '.$sharepoint_path.': '.$!);
print " written ok\n";

# Finally notify autofs of configuration changes
print "* Notifying autofs of changes...";
&_do('automount -vc');
print " all done, ok\n";

# Open folder in the Finder
&_do("open '$mount_path'");

print "* Please update your scripts, Automator workflows, and applications to use the paths:\n";
foreach my $sharepoint (@sharepoints) {
	my $full_path = File::Spec->catdir($mount_path,$sharepoint->{'name'});
	print "$full_path\n";
}

=pod _do
Perform a shell command and die on error.
=cut
sub _do {
	my( $command ) = @_;
	my $output = `$command`;
	die("[".__PACKAGE__."] '$command' failed: ${^CHILD_ERROR_NATIVE}: $output\n") if (${^CHILD_ERROR_NATIVE});
	return $output;
}

=pod LICENSE

The MIT License (MIT)

Copyright (c) 2013 Graham Miln, http://miln.eu

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut

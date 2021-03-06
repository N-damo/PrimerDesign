# Copyright (c) 2007
# Triinu Koressaar and Maido Remm
# All rights reserved.
# 
#     This file is part of the oligotm library.
# 
#     The oligotm library is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 2 of the License, or
#     (at your option) any later version.
# 
#     The oligotm library is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with the oligtm library (file gpl.txt in the source
#     distribution); if not, write to the Free Software
#     Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

use strict;
use warnings 'all';
use Getopt::Long;
use constant EPSILON => 1e-5;

my $do_valgrind;

if (!GetOptions('valgrind', \$do_valgrind)) {
    print STDERR "Usage: $0 [ --valgrind ]\n";
    exit -1;
}
my $valgrind_format
    = "/usr/local/bin/valgrind --leak-check=yes "
    . " --show-reachable=yes --log-file-exactly=oligotm.%0.3d.valg ";

my $nr=1;
my $failure=0;

die "Cannot execute ../src/oligotm" unless -x '../src/oligotm';

print STDERR "Tests nr $nr-";

open F, "./oligotm.txt" or die "Cannot open oligotm.txt\n";
while(<F>){
    chomp;
    next if $. == 1;
    my @tmp=split(/\t/);
    my $valgrind_prefix = $do_valgrind ? sprintf($valgrind_format, $nr) : '';
    my $cmd = 
	"$valgrind_prefix "
	. " ../src/oligotm -tp $tmp[1] -sc $tmp[2] -mv $tmp[3] "
	. " -dv $tmp[4] -n $tmp[5] $tmp[0] |";
    open(CMD, $cmd); # execute the command and take the output
    my $tm=<CMD>;
    chomp $tm;
    close(CMD);
    if($tm){
	if(($tm-$tmp[6])>EPSILON) {
	    $failure++;
	    print STDERR "$cmd FAILED (expected $tm, got $tmp[6])\n";
	}
    } else {
	$failure++;
	print STDERR  "$cmd FAILED (no output)\n";
    }
    $nr++;
}
close F;

$nr--;

if ($do_valgrind) {
    my $r = system "grep ERROR *.valg | grep -v 'ERROR SUMMARY: 0 errors'";
    if (!$r) { 
	# !$r because grep returns 0 if something is found,
	# and if something is found, we have a problem.
	print STDERR "valgrind found errors\n";
    }
}

if(!$failure){
    print STDERR "$nr: OK\n";
}
else{
    print STDERR "$nr: $failure FAILURES\n";
}

#!/usr/bin/perl -w

use strict;
use autodie;

while (<>) {
	chomp;
	my @verbs = split /\s+/;
	foreach my $verb (@verbs) {
		printf "$verb ";
	}
	printf "\n";
}

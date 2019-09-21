#!/usr/bin/perl -w

use strict;
use FindBin;
use lib "$FindBin::Bin/lib/";

use StatCollect;

#TODO: Add auto detect feature
my $ifs = get_ifs;
my @ports = @{$ifs};
my @net_stats = ();
my $cpu_stats = undef;

foreach my $port (@ports) {
	start_ethtool $port;
}
start_proc_cpu;
start_proc_interrupts;

sleep 25;

foreach my $port (@ports) {
	my $stat = stop_ethtool $port;
	push(@net_stats, $stat);
}

$cpu_stats = stop_proc_cpu;
my $irq = stop_proc_interrupts;
printf "irq_total: $irq\n";
printf "cpu_total: %3.2f\n", ${$cpu_stats}[0];

my $idx = 0;
foreach my $core (@{$cpu_stats}[1 .. $#$cpu_stats]) {
	printf "cpu_%d: %3.2f\n", $idx++, $core;
}

foreach my $key (keys($net_stats[0])) {
	my $idx = 0;
	my $total = 0;

	foreach my $stat (@net_stats) {
		printf "%s_%s: %d\n", $ports[$idx++], $key, $$stat{$key};
		$total += $$stat{$key};
	}
	printf "Total_%s: %d\n", $key, $total;
}

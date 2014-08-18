#!/usr/bin/perl

use strict;
use Spreadsheet::WriteExcel;
use Getopt::Long;
use DBI;

my $outputPath='';
my $sqlite_format = 0;
if (!GetOptions('output:s' => \$outputPath, 'sqlite' => \$sqlite_format)) {
print STDERR "NinkaWrapper version 1.1

Usage $0 -s -o <OutputPath> -- <file1> <file2> ...

  -s Export to SQLite form. (default is xls)

  -o The output path of the result file.

\n";

    exit 1;	
}

if (substr($outputPath,-1) ne "/") {
	$outputPath = $outputPath.'/';
}

my @files = @ARGV;

if ($sqlite_format) {

	my $driver   = "SQLite";
	my $database = "${outputPath}result.db";
	my $dsn = "DBI:$driver:dbname=$database";
	my $userid = "";
	my $password = "";
	my $dbh = DBI->connect($dsn, $userid, $password, { AutoCommit => 0,  RaiseError => 1 })
						  or die $DBI::errstr;
						  
	my $stmt = qq(CREATE TABLE IF NOT EXISTS LICENSE
		  (FILENAME           TEXT    NOT NULL,
		   LICENSE            TEXT     NOT NULL););
		   
	my $rv = $dbh->do($stmt);
	if($rv < 0){
	   print $DBI::errstr;
	}
	
	my $sth = $dbh->prepare('INSERT INTO LICENSE (FILENAME, LICENSE) VALUES (?, ?)');

	my $row = 1;
	foreach my $file (@files) {

		my $r = `ninka.pl -d $file`;
		my @line=split(/;/, $r);

		my @values=($line[0], $line[1]);
		$sth->execute(@values);

		$row++;
	}
	
	$dbh->commit;

	$dbh->disconnect();
					  
} else {
	# Create a new Excel workbook
	my $workbook = Spreadsheet::WriteExcel->new("${outputPath}result.xls");

	# Add a worksheet
	my $worksheet = $workbook->add_worksheet();

	$worksheet->freeze_panes(1, 0); # Freeze the first row

	# Set the width of each column
	$worksheet->set_column(0, 0,  50);
	$worksheet->set_column(1, 1,  25);
	$worksheet->set_column(2, 6,  5);
	$worksheet->set_column(7, 7,  50);

	my $format = $workbook->add_format(); # Add a format
	$format->set_bold();

	# Set title
	$worksheet->write(0, 0, 'File Name', $format);
	$worksheet->write(0, 1, 'License', $format);

	my $row = 1;
	foreach my $file (@files) {

		my $r = `ninka.pl -d $file`;
		my @line=split(/;/, $r);

		my $col=0;
		foreach my $item (@line) {
			
			$worksheet->write($row, $col, $item);
			$col++;
		}
		$row++;
	}
}




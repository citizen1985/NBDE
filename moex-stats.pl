use 5.010;
use Org::Parser;
use Encode qw/encode decode/;
my $orgp = Org::Parser->new();
my (%HoA, $lnk, @drills);
binmode(STDOUT, ":utf8");
say '#+STARTUP: hidestars';
my $qdoc = $orgp->parse_file("$ENV{HOME}/Dropbox/org/鐵特.org");
$qdoc->walk(sub {
     my ($el) = @_;
     $lnk=$el->get_property('ID', 0) if $el->isa('Org::Element::Headline') and $el->level == 3;
     push @drills, [$el->get_property('DRILL_AVERAGE_QUALITY', 0), $el->parent->parent->title->as_string.'/'.$el->parent->title->as_string.'/'.$el->title->as_string, $el->get_property('ID', 0)] if $el->isa('Org::Element::Headline') and $el->get_property('ID', 0) and $el->get_property('DRILL_AVERAGE_QUALITY', 0);
     return unless $el->isa('Org::Element::Link');
     if ($el->link=~m/^id:(.*?)$/){
	my $quizpath=join '//',$el->parent->parent->parent->title->as_string,"[[id:$lnk][".$el->parent->parent->title->as_string."]]",$lnk; #考試年度、題號、題目id
	push @{ $HoA{$1} }, $quizpath; #存儲至課文連結，及對應的所在題、年
     }});
#say join "\n",map{"$_->[0],[[id:$_->[2]][$_->[1]]]"} (sort{$a->[0] <=> $b->[0]} @drills)[0..499];
#exit 0;
CrossOp("$ENV{HOME}/Dropbox/ref/運輸學大意.org","運輸學");
CrossOp("$ENV{HOME}/Dropbox/org/企業管理.org","企業管理");
CrossOp("$ENV{HOME}/Dropbox/org/公文製作原理與實作.org","公文製作原理與實作");
CrossOp("$ENV{HOME}/Dropbox/org/搶救國文大作戰.org","搶救國文大作戰");
CrossOp("$ENV{HOME}/Dropbox/org/公民.org","公民");
CrossOp("$ENV{HOME}/Dropbox/org/法學大意.org","法學大意");
sub CrossOp{
	my ($fn,$title)= @_;
	my @topics, @topics_count, %topicsH, %examsH=(), @examsA=[], %qnoH;
	my $doc = $orgp->parse_file($fn);	# parse a file
	say decode("utf8", "* $title stats");
	$doc->walk(sub { 			# walk the document tree
		my ($el) = @_;
		return unless $el->isa('Org::Element::Headline');
		push @topics, $el;
		$topicsH{$el}=0;
		$topicsH{$el}=$topicsH{$el}+@{$HoA{$el->get_property('ID')}} if(( defined $el->get_property('ID'))&&(exists($HoA{$el->get_property('ID')})));
		foreach my $test(@{$HoA{$el->get_property('ID')}}){
			my ($examname,$qno,$lnk)=split('//',$test);
			$examsH{$examname}{$qno}=$lnk;
			push @{$qnoH{$el}{$examname}},$qno;
		}});
	foreach my $el(reverse @topics){
		$topicsH{$el->parent}=$topicsH{$el->parent}+$topicsH{$el} if ($topicsH{$el}>0) and (defined($el->parent->parent));
	}
	say "    :PROPERTIES:\n    :COLUMNS: %70ITEM %3DCOUNT %4DRILLS\n    :END:";
#	say "    :PROPERTIES:\n    :COLUMNS: %70ITEM %3DCOUNT %4DRILLS %5",join (" %5",sort keys %examsH)," %5LINK\n    :END:";
	say "#+BEGIN: columnview :hlines 1 :id local\n\n#+END";
	say join ('',map {"\n$_:(".scalar(keys %{$examsH{$_}}).'):'.join(', ',map{$_->[1]} sort{$a->[0] <=> $b->[0]} map{[substr($_,-4,2),$_]} keys %{$examsH{$_}})} sort keys %examsH);
	foreach my $el(@topics){
		if($topicsH{$el}>0){
			say '*'x(1+$el->level), " ", $el->title->as_string,"\n    :PROPERTIES:\n    :DRILLS:",scalar(@{ $HoA{$el->get_property('ID')}}),"\n    :DCOUNT:",$topicsH{$el};
			say "    :END:" ;
		    say '|',join('|',map {sprintf("%8s",$_)} sort keys %examsH),'|',"    [[id:",$el->get_property('ID'),"][LINK]]",'|';
		    say '|',join ('|',map {' 'x(10-4*scalar(@{$qnoH{$el}{$_}})-((1 > scalar(@{$qnoH{$el}{$_}}))?2:0)).join(', ',@{$qnoH{$el}{$_}})} sort keys %examsH),'|';
		} #else{say '*'x(1+$el->level), " ", $el->title->as_string ,(defined($el->parent->parent))?"non-top":"top-level";}
	}}

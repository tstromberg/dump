#!/usr/bin/perl
# mini multiple choice testing app written by Thomas Stromberg <thomas@stromberg.org>
# $Id: brutelearn.pl,v 1.4 2002/10/15 00:19:58 strombt Exp $

use strict;

use vars '%Question';
&initialize;

sub clear {
        system("clear");
        system("cls");
}

sub initialize {
	my ($answer, $num_to_ask);
	srand;
	if (! $ARGV[0]) {
		die("You must specify a test file.\n");
	}
	&read_file($ARGV[0]);
	my $num_questions = values %Question;
    &clear;
	print("$num_questions questions are on this test, how many would you like in a sitting? (25)\n");
	chomp($num_to_ask = <stdin>);
	if (1 > $num_to_ask) {
		$num_to_ask = 25
	}

	while($answer ne "placeholder") {
		&run_tests($num_to_ask, 1);
		&show_results;
		print("Press A to run the test (A)gain.\n");
		$answer = <STDIN>;
		chomp($answer);
		if ($answer !~ /^a/i) {
			print("Thanks for using brutelearn. exiting.\n");
			exit;
		}
	}

}

sub read_file {
	my ($filename) = @_;
	my ($type, $data, $last_question, $question_num, $answer_num);
    my ($total_answers, @answers);
	open(TESTFILE, "<$filename") || die "Can't open $filename: $!";
    print("* Reading $filename\n");
    my ($line) = 0;
    my ($errors) = 0; 
	foreach (<TESTFILE>) {
		chomp;
		($type, $data) = split(/: /, $_, 2);
        ++$line;
		if ($data eq "") {
			next
		}

        #print("type: $type\n");
		if (($type eq "Q") || ($type eq "END ")) {
			# may as well sanity check in case the quizzer forgot a right answer
			if (($last_question) && ($Question{$question_num}{answer} eq "")) {
				print("[$line] (q$question_num) \"$last_question\" had no answer. See: $Question{$question_num}{answer}\n");
                ++$errors;
			}

            $total_answers = @answers;
            foreach (@answers) {
                #print("($question_num) pre-random: $_\n");
            }


            foreach (sort { $a <=> rand($total_answers + 1) } @answers) {
                #print("($question_num) post-random: $_ ($total_answers)\n");
                ++$answer_num;
                $Question{$question_num}{$answer_num}=$_;
            }

			++$question_num;
			$answer_num = 0;
			$Question{$question_num}{question} = $data;
			$last_question = $data;
			undef @answers;
		}
		elsif ($type eq "R") {
			$Question{$question_num}{reference} = $data
		}
		elsif ($type eq "N") {
			$Question{$question_num}{note} = $data
		}
		elsif (($type eq "W") || ($type eq "A")) {
			push(@answers, $data);
			#print("set answer to $question_num to $data\n");
			if ($type eq "A") {
				if ($Question{$question_num}{answer} ne "") {
					print("[$line] (q$question_num) * \"$last_question\" has more then one answer\n");
                    ++$errors;
					next;
				} else {
                    $Question{$question_num}{answer} = $data;
                    #print("($question_num) answer =  $Question{$question_num}{answer} \n");
				}
			}
		}
		elsif ($type) {
			print("[$line] (q$question_num) * Unknown type tag \"$type\" for $_\n");
            ++$errors;
		}
	}
	print("- $question_num questions were loaded.\n");
    if ($errors) {
           print("* $errors errors detected. Please correct.\n");
           exit;
    }
}


sub run_tests {
	my ($max_questions, $random) = @_;
	my ($my_question, $questions_asked, $answer, $i, $answered_right, @answers, $answer_num, $answer_total);

	# lame way to guess at the tests to use, but..
	my $num_questions = values %Question;
	#print("Press Enter to take the test..\n");
	#$answer = <STDIN>;

	while ($questions_asked != $max_questions) {
		$my_question = int(rand($num_questions)) + 1;
		if ($Question{$my_question}{response} ne "") {
			next;
		}
		++$questions_asked;
		undef $answered_right;


		while (! $answered_right) {
            &clear;
			print("$questions_asked of $max_questions questions\n");
			print("============================================================\n");

			print("$my_question) $Question{$my_question}{question}\n\n");

			undef @answers;
   			# lame limitation. There can only be 50 answers to a question. VERY stupid.
			for ($i = 0; $i < 50; ++$i) {
				if ($Question{$my_question}{$i} ne "") {
					push(@answers, $i);
				}
			}

			$answer_num = 0;
            $answer_total = @answers;
            # multiple choice
            
            
            if ($answer_total > 1) {
                foreach (@answers) {
                    print("($_)  $Question{$my_question}{$_}\n");
                }
    
                print("\n\n\n> ");
                $answer = <STDIN>;
                chomp($answer);
    
                # check for valid answer. really really ugly man.
                if (($answer > 0) && ($answers[$answer-1])) {
                    $Question{$my_question}{response} = $answer;
                     ++$answered_right;
                } else {
                    print("** $answer is not a valid choice. \n");
                }
           } else {
                print("\n\n\n> ");
                $answer = <STDIN>;
                chomp($answer);
                
                 # Stupid, yes.
                 $Question{$my_question}{response} = 1;
                 $Question{$my_question}{1} = $answer;

                 if (length($answer) > 1) {
                     ++$answered_right;
                 } else {
                     print("** Please give an answer. \n");
                
                }
           }
		}


	}
}

sub show_results {
# lame way to guess at the tests to use, but..
	my $num_questions = values %Question;
	my ($num_tested, $num_wrong, $percentage, $i, $correct, $wrong);
	my ($answer, $response, $response_data);

    &clear;
	print("==============================================\n");
	print("Questions to review:\n");
	print("==============================================\n\n");

	$num_wrong = 0;

	for ($i = 0; $i < $num_questions; ++$i) {
		# if answered
		if ($Question{$i}{response}) {
            $response = $Question{$i}{response};
            $response_data = $Question{$i}{$response};
            #print("$Question{$i}{answer} ne $response_data\n");
			if (uc($Question{$i}{answer}) ne uc($response_data)) {
				$wrong = $Question{$i}{response};
				print("$i) $Question{$i}{question}\n");
				if ($Question{$i}{note}) {
					print("**** $Question{$i}{note}\n\n");
				}
				if ($Question{$i}{reference}) {
					print("    [$Question{$i}{reference}]\n\n");
				}
				print(" Correct:    $Question{$i}{answer}\n");
				print(" Your Choice: $response_data\n\n");
				++$num_wrong;
			}
			++$num_tested
		}
	}

	$percentage = int((($num_tested - $num_wrong) / $num_tested) * 100);
	print("================================================\n");
	print("Total Questions: $num_questions\n");
	print("Total Asked:     $num_tested\n");
	print("Total Wrong:     $num_wrong\n");
	print("Percentage:      ${percentage}%\n");
	print("================================================\n");

}

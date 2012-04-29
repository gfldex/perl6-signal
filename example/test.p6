#!/usr/bin/env perl6

BEGIN { @*INC.unshift: './lib'; }

use v6;
use Signal;

say "  simple usecase";

class Input {
	has Str $.text is rw;
	our method sig_changed(Str $s) is signal {};
	our method sig_keyup is signal {};
	
	method fake_event_handler() {
		$.text = (1..10).pick(5).join;
		$.sig_changed($.text);
	}
}

class Button {
	has Str $.text is rw;
	our method sig_pressed is signal {};
	our method sig_lowered is signal {};
	our method sig_raised is signal {};
	
	method fake_event_handler() { self.sig_pressed }
}

class Person {
	has Str $.name is rw;
	has Int $.age is rw;
	has Int $.sexiness is rw;
	
	our method set_name($name){ $.name = $name }
	our method set_age($age){ $.age = $age.Int }
	our method set_sexiness($sexiness) { $.sexiness = $sexiness.Int }
	our method foo(){};
}

class PersonDialog {
	has Person $.person;
	has Input $.name;
	has Input $.age;
	has Input $.sexiness;
	has Button $.ok;
	
	method new(){
		my Person $person .= new, 
		my Input $name .= new, 
		my Input $age .= new, 
		my Input $sexiness .= new, 
		my Button $ok .= new(:text('OK'));
			
		my $self = self.bless(*, person => $person, name => $name, age => $age, sexiness => $sexiness, ok => $ok);
		
		connect($name, &Input::sig_changed, $person, &Person::set_name);
		connect($age, &Input::sig_changed, $person, &Person::set_age);
		connect($sexiness, &Input::sig_changed, $person, &Person::set_sexiness);
		connect($ok, &Button::sig_pressed, $self, &PersonDialog::finished);

		return $self;
	}
	
	our method finished() {
		die "ohh no!" unless $.person.name && $.person.age && $.person.sexiness;
		say "Person name: {$.person.name}, age: {$.person.age}, sexiness: {$.person.sexiness}";
	}
}

my PersonDialog $pd .= new;

.fake_event_handler for $pd.name, $pd.age, $pd.sexiness, $pd.ok;

say "  return value tests";

sub sig1(Int $i --> Str) is signal {}
sub slot1(Int $i --> Str){ $i.Str }
sub slot2(Int $i --> Str){ $i.Str }

(&sig1).connect(&slot1).connect(&slot2);

say sig1(10).perl;

sub sig2() is signal {}
sub slot3(--> Int){ 42 }
sub slot4(--> Int){ 21 }

(&sig2).connect(&slot3).connect(&slot4);

say sig2().perl;

class A { our method sig5(Int $i --> Str) is signal {} }
class B { our method slot5(Int $i --> Str) { $i.Str } }
class C { our method slot6(Int $i is copy --> Str) { (++$i).Str } }

my $a = A.new;
my $b = B.new;
my $c = C.new;

connect($a, &A::sig5, $b, &B::slot5);
connect($a, &A::sig5, $c, &C::slot6);
say $a.sig5(11).perl;

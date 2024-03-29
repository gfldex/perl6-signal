use v6;

module Signal;

role Signal is export {
  has @.slots; # a nice list of callbacks (that are methods)

  multi method connect(Any:D $sender, Any:D $rcpt, Method $method){
    @.slots.push([$sender, self, $rcpt, $method]);
    return self;
  }

  multi method connect(Any:D $rcpt, Method $method){
    @.slots.push([Mu, self, $rcpt, $method]);
    return self;
  }

  multi method connect(Any:D $sender, Method $signal, Routine $slot){
    @.slots.push([$sender, $signal, Mu, $slot]);
    return self;
  }

  multi method connect(Routine $r){
    @.slots.push([Mu, self, Mu, $r]);
    return self;
  }

  method disconnect(Mu $sender, Mu $rcpt, Routine $slot){
    my $offset = 0;
    for @.slots -> $slot {
      @.slots.splice($offset, 1) if $slot == [$sender, self, $rcpt, $slot];
      $offset++;
    }
      return self;
  }

  multi method is_connected(Mu $sender, Mu $rcpt, Routine $slot){
    return if [$sender, self, Mu, $slot] == any(@.slots);
  }

  multi method is_connected(Mu $rcpt, Routine $slot){
    return if [Mu, self, Mu, $slot] == any(@.slots);
  }
}

multi trait_mod:<is>(Routine $_signal, :$signal!) is export {
  $_signal does Signal;

  $_signal.slots; # WORKAROUND RT112666

  multi call_handler(){
    my @ret;
    for $_signal.slots -> [$sender, $signal, $receiver, $slot] {
      @ret.push($receiver.$slot()) if $receiver;
      @ret.push($slot()) if !$receiver;
    }
      return @ret;
  }

  multi call_handler(*@args){
    my @ret;
    for $_signal.slots -> [$sender, $signal, $receiver, $slot] {

      # we need to do some magic with the first argument because Routine don't
      # really got one and Method may have the wrong one. In our case self
      # will be pointing to the actual signal.

      @args[0] = $receiver if $slot ~~ Method && $receiver;
      @args.shift if $sender && $signal ~~ Method && !$receiver && $slot !~~ Method;
      @ret.push($slot(|@args));
    }
    return @ret;
  }

  $_signal.wrap(&call_handler);
}

multi sub connect(Any:D $sender, Method $signal, Any:D $rcpt, Method $slot) is export {
  $signal.connect($sender, $rcpt, $slot);
}

multi sub connect(Signal $signal, Any:D $rcpt, Method $slot) is export {
  $signal.connect($rcpt, $slot);
}

multi sub connect(Any:D $sender, Method $signal, Routine $slot) is export {
  $signal.connect($sender, $signal, $slot);
}

multi sub connect(Routine $signal, Routine $slot) is export {
  $signal.connect($slot);
}

multi disconnect(Any:D $sender, Method $signal, Any:D $receiver, Method $slot) is export {
  $signal.disconnect($sender, $receiver, $slot);
}

multi disconnect(Signal $signal, Any:D $receiver, Method $slot) is export {
  $signal.disconnect(Mu, $receiver, $slot);
}

multi disconnect(Any:D $sender, Method $signal, Routine $slot) is export {
  $signal.disconnect($sender, Mu, $slot);
}

multi disconnect(Routine $signal, Routine $slot) is export {
  $signal.disconnect(Mu, Mu, $slot);
}

sub test () {
  my @results;

  my class A {
    method sig1 (Int $i) is signal {...}
  }

  my class B {
    method slot1 (Int $i) { 2*$i }
  }

  my $a = A.new;
  my $b = B.new;

  connect($a, &A::sig1, $b, &B::sig1);

  @results.push(True) if $a.sig1.is_connected($b, &B::sig1);
  @results.push(True) if $a.sig1(5) == 10;

  return @results;
}

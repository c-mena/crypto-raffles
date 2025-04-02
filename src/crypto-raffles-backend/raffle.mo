import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat16 "mo:base/Nat16";
import Principal "mo:base/Principal";
import Random "mo:base/Random";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";
import TrieSet "mo:base/TrieSet";

import { phash } "mo:map/Map";
import DateTimeComp "mo:datetime/Components";
import Map "mo:map/Map";

import Utils "./utils";

module {
  public type Id = Nat;
  public type Ticket = Nat16;
  public type Price = Nat;

  public type ResultT<T> = Result.Result<T, Text>;

  public type Status = {
    #Open; // Open for ticket purchases
    #Closed; // Closed for ticket purchases or tickets sold out
    #Drawn; // Draw has been conducted and winners have been selected
  };

  public type Token = {
    #ICP;
    #BTC;
    #ETH;
  };

  public type Winner = {
    player : Principal;
    ticket : Ticket;
  };

  public type Summary = {
    status : Status;
    availableTickets : Ticket;
    purchasedTickets : Ticket;
    players : Id;
    winners : Id;
  };

  // Immutable data
  public type Setup = {
    owner : Principal;
    creationDate : DateTimeComp.Components;
    drawDate : DateTimeComp.Components;
    ticketPrice : Price;
    priceToken : Token;
    maxTickets : Ticket;
    prizes : [Price];
    prizeToken : Token;
  };

  // Mutable data
  public class Raffle(_setup : Setup) {
    public let setup : Setup = _setup;
    public var status_ : Status = #Open;
    public var availableTicketsCount_ : Ticket = setup.maxTickets;
    public var purchasedTicketsCount_ : Ticket = 0;
    public var players_ : Map.Map<Principal, [Ticket]> = Map.new<Principal, [Ticket]>();
    public var winners_ : ?[Winner] = null; // Prize is obtained from setup.prizes, in the corresponding position
    public var ticketIsAvailable_ = ?Array.init<Bool>(Nat16.toNat(setup.maxTickets), true);
  };

  public func setup(raffle : Raffle) : Setup = raffle.setup;
  public func status(raffle : Raffle) : Status = raffle.status_;
  public func playersCount(raffle : Raffle) : Nat = Map.size(raffle.players_);
  public func purchasedTicketsCount(raffle : Raffle) : Ticket = raffle.purchasedTicketsCount_;
  public func availableTicketsCount(raffle : Raffle) : Ticket = raffle.availableTicketsCount_;

  public func summary(raffle : Raffle) : Summary {
    var winnersSize = 0;
    if (raffle.status_ == #Drawn) {
      switch (raffle.winners_) {
        case (null) { () };
        case (?winners) {
          winnersSize := Array.size(winners);
        };
      };
    };

    let summary : Summary = {
      status = raffle.status_;
      availableTickets = raffle.availableTicketsCount_;
      purchasedTickets = raffle.purchasedTicketsCount_;
      players = Map.size(raffle.players_);
      winners = winnersSize;
    };
    summary;
  };

  public func purchasedTickets(raffle : Raffle, player : Principal) : ResultT<[Ticket]> {
    switch (Map.get(raffle.players_, phash, player)) {
      case (null) { #err(Utils.msg.playerNotFound) };
      case (?tickets) { #ok(tickets) };
    };
  };

  public func winners(raffle : Raffle) : ResultT<[Winner]> {
    if (raffle.status_ != #Drawn) {
      return #err(Utils.msg.raffleNotCarriedOut);
    };

    switch (raffle.winners_) {
      case (null) { #err(Utils.msg.unhandledError) };
      case (?winners) { #ok(winners) };
    };
  };

  // returns the number of tickets actually paid in this transaction
  public func buySelectedTickets(raffle : Raffle, buyer : Principal, tickets : [Ticket]) : ResultT<Ticket> {
    if (raffle.status_ == #Drawn) {
      return #err(Utils.msg.raffleAlreadyDrawn);
    };
    if (raffle.availableTicketsCount_ == 0) {
      return #err(Utils.msg.noTicketsAvailable);
    };

    var newTicketsCount : Ticket = 0;
    var purchasedTickets = Buffer.Buffer<Ticket>(0);
    label oldBuy switch (Map.get(raffle.players_, phash, buyer)) {
      case (?oldTickets) {
        purchasedTickets := Buffer.fromArray<Ticket>(oldTickets);
      };
      case (null) { break oldBuy };
    };

    switch (raffle.ticketIsAvailable_) {
      case (null) { return #err(Utils.msg.unhandledError) };
      case (?ticketIsAvailable) {
        label nextTicket for (ticket in tickets.vals()) {
          if (ticket < 1 or ticket > raffle.setup.maxTickets) {
            continue nextTicket;
          };
          let idx : Nat = Nat16.toNat(ticket) - 1;
          if (ticketIsAvailable[idx]) {
            purchasedTickets.add(ticket);
            newTicketsCount += 1;
            ticketIsAvailable[idx] := false;
          } else {
            // Ticket has been previously purchased
            continue nextTicket;
          };
        };
      };
    };

    if (newTicketsCount > 0) {
      raffle.purchasedTicketsCount_ += newTicketsCount;
      raffle.availableTicketsCount_ -= newTicketsCount;
      if (raffle.availableTicketsCount_ == 0) {
        raffle.status_ := #Closed;
        raffle.ticketIsAvailable_ := null; // frees memory
      };
      Map.set(raffle.players_, phash, buyer, Buffer.toArray<Ticket>(purchasedTickets));
    };

    return #ok(newTicketsCount);
  };

  // returns the number of tickets actually paid in this transaction
  public func buyRandomTickets(raffle : Raffle, buyer : Principal, ticketsCount : Nat) : async ResultT<Ticket> {
    if (raffle.status_ == #Drawn) {
      return #err(Utils.msg.raffleAlreadyDrawn);
    };
    if (ticketsCount == 0) {
      return #err(Utils.msg.invalidArguments);
    };
    if (raffle.availableTicketsCount_ == 0) {
      return #err(Utils.msg.noTicketsAvailable);
    };

    var ticketsToBuy : Nat = ticketsCount;
    if (Nat16.fromNat(ticketsCount) > raffle.availableTicketsCount_) {
      ticketsToBuy := Nat16.toNat(raffle.availableTicketsCount_);
    };

    switch (availableTickets(raffle)) {
      case (#ok(availableTickets)) {
        switch (await getUniqueRandomNumbers(ticketsToBuy, 0, Nat16.toNat(raffle.availableTicketsCount_ - 1))) {

          case (#ok(randomIndexes)) {
            let tickets = Array.map<Nat, Ticket>(randomIndexes, func i = availableTickets[i]);
            return buySelectedTickets(raffle, buyer, tickets);
          };
          case (_) { return #err(Utils.msg.unhandledError) };
        };
      };
      case (#err(err)) { return #err(err) };
    };
  };

  // Make the raffle immediately, ignoring drawDate configured. Only runnable by the creator of the raffle.
  public func makeTheDraw(raffle : Raffle, requestor : Principal) : async ResultT<[Winner]> {
    if (requestor != raffle.setup.owner) {
      return #err(Utils.msg.onlyOwnerCanDraw);
    };
    if (raffle.status_ == #Drawn) {
      return #err(Utils.msg.raffleAlreadyDrawn);
    };
    if (raffle.purchasedTicketsCount_ == 0) {
      let delayTodrawDate = DateTimeComp.toTime(raffle.setup.drawDate) - Time.now(); // nanoseconds
      if (delayTodrawDate > 0) {
        // There is time left to buy tickets
        return #err(Utils.msg.noTicketsPurchased);
      } else {
        // Drawn without winners
        raffle.status_ := #Drawn;
        raffle.winners_ := ?[];
        raffle.ticketIsAvailable_ := null; // frees memory
        return #ok([]);
      };
    };

    let prizesCount = raffle.setup.prizes.size();
    let buyedTickets = allPurchasedTickets(raffle);
    switch (await getUniqueRandomNumbers(prizesCount, 0, Nat16.toNat(raffle.purchasedTicketsCount_ - 1))) {
      case (#ok(winnerIndexes)) {
        let nullPrincipal = Principal.fromText("aaaaa-aa");
        var winners = Array.init<Winner>(prizesCount, { player = nullPrincipal; ticket = 0 });
        var i = 0;
        for (idx in winnerIndexes.vals()) {
          let winnerTicket = buyedTickets[idx];
          switch (findBuyer(raffle, winnerTicket)) {
            case (#ok(winner)) {
              winners[i] := {
                player = winner;
                ticket = winnerTicket;
              };
              i += 1;
            };
            case (_) {
              return #err(Utils.msg.unhandledError);
            };
          };
        };
        raffle.winners_ := ?Array.freeze(winners);
        raffle.status_ := #Drawn;
        raffle.ticketIsAvailable_ := null; // frees memory
        switch (raffle.winners_) {
          case (?winners) { return #ok(winners) };
          case (_) { return #err(Utils.msg.unhandledError) };
        };
      };
      case (_) {
        return #err(Utils.msg.unhandledError);
      };
    };
  };

  public func validateTicketsAvailability(raffle : Raffle, tickets : [Ticket]) : ResultT<Bool> {
    if (raffle.status_ == #Drawn) {
      return #err(Utils.msg.raffleAlreadyDrawn);
    };
    if (raffle.availableTicketsCount_ == 0) {
      return #err(Utils.msg.noTicketsAvailable);
    };
    if (tickets.size() == 0) {
      return #err(Utils.msg.invalidArguments);
    };

    switch (raffle.ticketIsAvailable_) {
      case (null) { return #err(Utils.msg.unhandledError) };
      case (?ticketIsAvailable) {
        label nextTicket for (ticket in tickets.vals()) {
          if (ticket < 1 or ticket > raffle.setup.maxTickets) {
            return #err(Utils.msg.invalidTicket);
          };
          if (ticketIsAvailable[Nat16.toNat(ticket) - 1]) {
            continue nextTicket;
          } else {
            return #ok(false);
          };
        };
      };
    };

    #ok(true);
  };

  public func availableTickets(raffle : Raffle) : ResultT<[Ticket]> {
    if (raffle.status_ == #Drawn) {
      return #err(Utils.msg.raffleAlreadyDrawn);
    };
    if (raffle.availableTicketsCount_ == 0) {
      return #ok([]);
    };

    let availableTickets = Array.init<Ticket>(Nat16.toNat(raffle.availableTicketsCount_), 0);
    switch (raffle.ticketIsAvailable_) {
      case (null) { return #err(Utils.msg.unhandledError) };
      case (?ticketIsAvailable) {
        var i : Nat = 0;
        for (ticket in Iter.range(1, Nat16.toNat(raffle.setup.maxTickets))) {
          if (ticketIsAvailable[ticket - 1]) {
            availableTickets[i] := Nat16.fromNat(ticket);
            i += 1;
          };
        };
      };
    };
    #ok(Array.freeze(availableTickets));
  };

  public func allPurchasedTickets(raffle : Raffle) : [Ticket] {
    if (raffle.purchasedTicketsCount_ == 0) {
      return [];
    };

    let buyedTickets = Array.init<Ticket>(Nat16.toNat(raffle.purchasedTicketsCount_), 0);
    var currentIndex = 0;

    for ((_, tickets) in Map.entries(raffle.players_)) {
      for (ticket in tickets.vals()) {
        buyedTickets[currentIndex] := ticket;
        currentIndex += 1;
      };
    };

    Array.freeze(buyedTickets);
  };

  public func findBuyer(raffle : Raffle, ticket : Ticket) : ResultT<Principal> {
    label nextPlayer for ((player, tickets) in Map.entries(raffle.players_)) {
      if (ticket < 1 or ticket > raffle.setup.maxTickets) {
        return #err(Utils.msg.invalidTicket);
      };
      switch (Array.find<Ticket>(tickets, func(buyedTicket) { buyedTicket == ticket })) {
        case (null) { continue nextPlayer };
        case (_) { return #ok(player) };
      };
    };
    return #err(Utils.msg.playerNotFound);
  };

  // Generates n non-repeated Nat random numbers in the range [min, max]
  // The generation becomes very slow as n approaches (max - min + 1).
  // TODO: Improve algorithm using https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle
  func getUniqueRandomNumbers(n : Nat, min : Nat, max : Nat) : async ResultT<[Nat]> {
    if (min > max) {
      return #err(Utils.msg.invalidArguments);
    };

    let range = max - min + 1;
    if (n > range) {
      // Insufficient range to generate n numbers
      return #err(Utils.msg.invalidArguments);
    };

    var random = Random.Finite(await Random.blob());
    var set = TrieSet.empty<Nat>(); // TrieSet guarantees to store unique numbers
    var result = Array.init<Nat>(n, 0);
    var count = 0;

    let comp = func(x : Nat, y : Nat) : Bool {
      return x == y;
    };

    while (count < n) {
      let randomValue = random.range(32); // Generates a random number in the range [0, 2^32 - 1]
      switch (randomValue) {
        case (?num) {
          let numInRange = min + (num % range);
          let hash = Hash.hash(numInRange);
          let trailMsg = "/" # debug_show (n) # " ...";
          if (not TrieSet.contains(set, numInRange, hash, comp)) {
            set := TrieSet.put(set, numInRange, hash, comp);
            result[count] := numInRange;
            count += 1;
            if (count % 10 == 0) {
              Debug.print("getUniqueRandNumbers:" # debug_show (count) # trailMsg);
            };
          };
        };
        case (_) {
          random := Random.Finite(await Random.blob());
        };
      };
    };
    Debug.print("getUniqueRandNumbers: End");
    return #ok(Array.freeze(result));
  };
};

import Array "mo:base/Array";
import DateTimeComp "mo:datetime/Components";
import Map "mo:map/Map";
import { nhash } "mo:map/Map";
import Nat "mo:base/Nat";
import Nat16 "mo:base/Nat16";
import Order "mo:base/Order";
import Principal "mo:base/Principal";
import Time "mo:base/Time";

import Raffle "./raffle";
import Utils "./utils";

actor {
  type ResultT<T> = Raffle.ResultT<T>;

  type Summary = {
    raffles : Nat;
    openRaffles : Nat;
    closedRaffles : Nat;
    drawnRaffles : Nat;
    players : Nat;
    purchasedTickets : Raffle.Ticket;
    totalPaided : Nat;
    prizesGiven : Nat;
  };

  let minTickets : Raffle.Ticket = 10;
  let maxPrixes : Nat = 100;
  let hash = nhash;

  stable var raffles = Map.new<Raffle.Id, Raffle.Raffle>();
  stable var summary = {
    var raffles = 0;
    var openRaffles = 0;
    var closedRaffles = 0;
    var drawnRaffles = 0;
    var players = 0;
    var purchasedTickets : Raffle.Ticket = 0;
    var totalPaided : Nat = 0;
    var winners = 0;
    var prizesGiven = 0;
  };

  public shared ({ caller }) func createRaffle({
    drawDate : DateTimeComp.Components;
    ticketPrice : Raffle.Price;
    priceToken : Raffle.Token;
    maxTickets : Raffle.Ticket;
    prizes : [Raffle.Price];
    prizeToken : Raffle.Token;
  }) : async ResultT<Raffle.Id> {

    if (not DateTimeComp.isValid(drawDate)) {
      return #err(Utils.msg.invalidDrawDate);
    } else if (prizes.size() == 0) {
      return #err("No prizes!");
    } else if (Nat.greater(prizes.size(), maxPrixes)) {
      return #err("Prizes should not exceed " # Nat.toText(maxPrixes));
    } else if (maxTickets < minTickets) {
      return #err("Max tickets must be at least " # Nat16.toText(minTickets) # " !");
    } else {
      let creationDate_ = DateTimeComp.fromTime(Time.now());
      label validDate switch (DateTimeComp.compare(drawDate, creationDate_)) {
        case (#less or #equal) { return #err(Utils.msg.invalidDrawDate) };
        case (_) { break validDate };
      };

      for (prize in prizes.vals()) {
        if (Nat.greater(ticketPrice, prize)) {
          return #err("Invalid prize!");
        };
      };

      let sortedPrizes : [Nat] = Array.sort<Nat>(
        prizes,
        func(a, b) : Order.Order {
          if (a > b) { #less } // descending order
          else if (a < b) { #greater } // a must come after b
          else { #equal };
        },
      );

      summary.raffles += 1;
      let id = summary.raffles;
      let setup : Raffle.Setup = {
        owner = caller;
        creationDate = creationDate_;
        drawDate = drawDate;
        ticketPrice = ticketPrice;
        priceToken = priceToken;
        maxTickets = maxTickets;
        prizes = sortedPrizes;
        prizeToken = prizeToken;
      };

      let raffle = Raffle.Raffle(setup);
      Map.set(raffles, hash, id, raffle);
      summary.openRaffles += 1;
      return #ok(id);
    };
  };

  public query func status() : async Summary {
    let inmutableSummary = {
      raffles = summary.raffles;
      openRaffles = summary.openRaffles;
      closedRaffles = summary.closedRaffles;
      drawnRaffles = summary.drawnRaffles;
      players = summary.players;
      purchasedTickets = summary.purchasedTickets;
      totalPaided = summary.totalPaided;
      winners = summary.winners;
      prizesGiven = summary.prizesGiven;
    };
    inmutableSummary;
  };

  public query func raffleSetup(id : Raffle.Id) : async ResultT<Raffle.Setup> {
    switch (raffle(id)) {
      case (null) { #err(Utils.msg.raffleNotFound) };
      case (?raffle) { #ok(raffle.setup) };
    };
  };

  public query func raffleStatus(id : Raffle.Id) : async ResultT<Raffle.Status> {
    switch (raffle(id)) {
      case (null) { #err(Utils.msg.raffleNotFound) };
      case (?raffle) { #ok(Raffle.status(raffle)) };
    };
  };

  public query func raffleAvailableTicketsCount(id : Raffle.Id) : async ResultT<Raffle.Ticket> {
    switch (raffle(id)) {
      case (null) { #err(Utils.msg.raffleNotFound) };
      case (?raffle) { #ok(Raffle.availableTicketsCount(raffle)) };
    };
  };

  public query func rafflePlayersCount(id : Raffle.Id) : async ResultT<Nat> {
    switch (raffle(id)) {
      case (null) { #err(Utils.msg.raffleNotFound) };
      case (?raffle) { #ok(Raffle.playersCount(raffle)) };
    };
  };

  public query func raffleValidateTicketsAvailability(id : Raffle.Id, tickets : [Raffle.Ticket]) : async ResultT<Bool> {
    switch (raffle(id)) {
      case (null) { #err(Utils.msg.raffleNotFound) };
      case (?raffle) { Raffle.validateTicketsAvailability(raffle, tickets) };
    };
  };

  public query func raffleAvailableTickets(id : Raffle.Id) : async ResultT<[Raffle.Ticket]> {
    switch (raffle(id)) {
      case (null) { #err(Utils.msg.raffleNotFound) };
      case (?raffle) { Raffle.availableTickets(raffle) };
    };
  };

  public shared ({ caller }) func raffleBuySelectedTickets(id : Raffle.Id, tickets : [Raffle.Ticket]) : async ResultT<Raffle.Ticket> {
    switch (raffle(id)) {
      case (null) { #err(Utils.msg.raffleNotFound) };
      case (?raffle) {
        let oldRafflePlayers = Raffle.playersCount(raffle);
        switch (Raffle.buySelectedTickets(raffle, caller, tickets)) {
          case (#ok(purchasedTickets)) {
            let newRafflePlayers = Raffle.playersCount(raffle);
            let totalPaided = raffle.setup.ticketPrice * Nat16.toNat(Raffle.purchasedTicketsCount(raffle));
            summary.purchasedTickets += purchasedTickets;
            summary.totalPaided += totalPaided;
            summary.players += newRafflePlayers - oldRafflePlayers;
            if (Raffle.status(raffle) == #Closed) {
              summary.openRaffles -= 1;
              summary.closedRaffles += 1;
            };
            #ok(purchasedTickets);
          };
          case (#err(err)) { #err(err) };
        };
      };
    };
  };

  public shared ({ caller }) func raffleBuyRandomTickets(id : Raffle.Id, ticketsCount : Nat) : async ResultT<Raffle.Ticket> {
    switch (raffle(id)) {
      case (null) { #err(Utils.msg.raffleNotFound) };
      case (?raffle) {
        let oldRafflePlayers = Raffle.playersCount(raffle);
        switch (await Raffle.buyRandomTickets(raffle, caller, ticketsCount)) {
          case (#ok(purchasedTickets)) {
            let newRafflePlayers = Raffle.playersCount(raffle);
            let totalPaided = raffle.setup.ticketPrice * Nat16.toNat(Raffle.purchasedTicketsCount(raffle));
            summary.purchasedTickets += purchasedTickets;
            summary.totalPaided += totalPaided;
            summary.players += newRafflePlayers - oldRafflePlayers;
            if (Raffle.status(raffle) == #Closed) {
              summary.openRaffles -= 1;
              summary.closedRaffles += 1;
            };
            #ok(purchasedTickets);
          };
          case (#err(err)) { #err(err) };
        };
      };
    };
  };

  public shared ({ caller }) func rafflePurchasedTickets(id : Raffle.Id) : async ResultT<[Raffle.Ticket]> {
    switch (raffle(id)) {
      case (null) { #err(Utils.msg.raffleNotFound) };
      case (?raffle) { Raffle.purchasedTickets(raffle, caller) };
    };
  };

  public query func rafflePurchasedTicketsCount(id : Raffle.Id) : async ResultT<Raffle.Ticket> {
    switch (raffle(id)) {
      case (null) { #err(Utils.msg.raffleNotFound) };
      case (?raffle) { #ok(Raffle.purchasedTicketsCount(raffle)) };
    };
  };

  public shared ({ caller }) func raffleMakeTheDraw(id : Raffle.Id) : async ResultT<[Raffle.Winner]> {
    switch (raffle(id)) {
      case (null) { #err(Utils.msg.raffleNotFound) };
      case (?raffle) {
        switch (await Raffle.makeTheDraw(raffle, caller)) {
          case (#ok(winners)) {
            var raffleTotalPrizes = 0;
            for (prize in raffle.setup.prizes.vals()) {
              raffleTotalPrizes += prize;
            };
            summary.winners += winners.size();
            summary.prizesGiven += raffleTotalPrizes;
            summary.openRaffles -= 1;
            summary.drawnRaffles += 1;
            #ok(winners);
          };
          case (#err(err)) { #err(err) };
        };
      };
    };
  };

  public query func raffleFindBuyer(id : Raffle.Id, ticket : Raffle.Ticket) : async ResultT<Principal> {
    switch (raffle(id)) {
      case (null) { #err(Utils.msg.raffleNotFound) };
      case (?raffle) { Raffle.findBuyer(raffle, ticket) };
    };
  };

  public query func raffleFindTickets(id : Raffle.Id, player : Principal) : async ResultT<[Raffle.Ticket]> {
    switch (raffle(id)) {
      case (null) { #err(Utils.msg.raffleNotFound) };
      case (?raffle) { Raffle.purchasedTickets(raffle, player) };
    };
  };

  public shared ({ caller }) func raffleFindMyTickets(id : Raffle.Id) : async ResultT<[Raffle.Ticket]> {
    switch (raffle(id)) {
      case (null) { #err(Utils.msg.raffleNotFound) };
      case (?raffle) { Raffle.purchasedTickets(raffle, caller) };
    };
  };

  public query func raffleWinners(id : Raffle.Id) : async ResultT<[Raffle.Winner]> {
    switch (raffle(id)) {
      case (null) { #err(Utils.msg.raffleNotFound) };
      case (?raffle) { Raffle.winners(raffle) };
    };
  };

  public query func raffleAllPurchasedTickets(id : Raffle.Id) : async ResultT<[Raffle.Ticket]> {
    switch (raffle(id)) {
      case (null) { #err(Utils.msg.raffleNotFound) };
      case (?raffle) { #ok(Raffle.allPurchasedTickets(raffle)) };
    };
  };

  func raffle(id : Raffle.Id) : ?Raffle.Raffle {
    Map.get(raffles, hash, id);
  };
};

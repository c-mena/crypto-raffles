# Crypto Raffles

*[Versión en español](README.es.md)*

## Description
Welcome to Crypto Raffles, a decentralized platform for raffles implemented on the [Internet Computer](https://internetcomputer.org/) blockchain.

Crypto Raffles enables the creation, management, and participation in raffles in a completely decentralized manner, ensuring a transparent and fair process through blockchain technology.

## Main Features

- **Raffle Creation**: Users can create new raffles by specifying draw date, ticket price, maximum number of tickets, and prizes.
- **Ticket Purchase**: Participants can buy specific or random tickets, per unit or in packs.
- **Availability Validation**: Automatic verification of ticket availability.
- **Raffle Drawing**: Random and verifiable process for winner selection. Only the authenticated raffle creator can request the drawing process.
- **Complete Transparency**: All information about purchased tickets, winners, and prizes is public and verifiable.
- **Secure Authentication**: Implementation of [Internet Identity](https://identity.ic0.app/) to ensure secure, private, and decentralized authentication.

## Technologies Used

- **Motoko**: Native programming language of Internet Computer.
- **Internet Computer Protocol (ICP)**: Decentralized blockchain hosting the project.
- **DFINITY Canister SDK**: Tools for development and deployment on ICP.

## Raffle States

1. **Open**: Available for ticket purchases.
2. **Closed**: Closed for purchases (all tickets sold).
3. **Drawn**: Raffle completed and winners selected.

## Technical Functionalities

- Secure random number generation for winner selection.
- Support for multiple tokens for payments (ICP, BTC, ETH).
- Efficient storage system for available and sold tickets.
- Mechanisms to prevent duplicate purchases and validate arguments.
- Global system statistics (total raffles, tickets sold, prizes awarded).

## How to Deploy

### Prerequisites
- [DFINITY Canister SDK (dfx)](https://sdk.dfinity.org/docs/quickstart/local-quickstart.html)
- Node.js and curl
- [Mops](https://mops.one/) package manager

### Local Deployment Steps

1. Clone the repository:
   ```bash
   git clone https://github.com/c-mena/crypto-raffles
   cd crypto-raffles
   ```

2. Install dependencies:
   - Install the IC SDK ([installation instructions](https://internetcomputer.org/docs/building-apps/getting-started/install))
   - Install Mops CLI:
     ```bash
     # With curl
     curl -fsSL cli.mops.one/install.sh | sh
     # Or with npm
     npm i -g ic-mops
     ```
   - Initialize and install project dependencies:
     ```bash
     mops init
     mops install
     ```

3. Start the local Internet Computer replica:
   ```bash
   dfx start --background
   ```

4. Deploy the canisters:
   ```bash
   dfx deploy
   ```

### Mainnet Deployment

1. Ensure you have sufficient cycles in your account:
   ```bash
   dfx identity get-principal
   dfx ledger balance
   ```

2. Deploy to the main network:
   ```bash
   dfx deploy --network ic
   ```

## Backend Usage

The backend exposes multiple functions to interact with raffles:

- `status`: Summary of all raffles
- `createRaffle`: Create a new raffle
- `raffleSetup`: Check the configuration of a raffle
- `raffleStatus`: Check the status of a raffle
- `raffleBuySelectedTickets`: Purchase specific tickets
- `raffleBuyRandomTickets`: Purchase random tickets
- `raffleMakeTheDraw`: Conduct the raffle and select winners
- `raffleWinners`: Check the winners of a raffle
- `raffleAvailableTickets`: Check available tickets in a raffle
- `rafflePurchasedTickets`: Check purchased tickets in a raffle
- `raffleFindBuyer`: Find the buyer of a specific ticket in a raffle
- `raffleFindTickets`: Find tickets purchased by an identity in a raffle
- ...

When deploying the project, URLs are automatically generated to access a basic Candid UI interface. This interface allows you to evaluate all backend functionalities interactively, without the need for a custom frontend. Each backend function can be tested directly from this interface, facilitating testing and verification of the system's operation.

## Future Development

- Web user interface
- Integration with digital wallets
- Notification system for winners
- Smart contracts for automatic prize distribution

## Contributions

Contributions are welcome. Please follow these steps:

1. Fork the repository
2. Create a new branch (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Create a new Pull Request

---

*This project was developed as a proof of concept in Motoko, my first program in this language. 😊*

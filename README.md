# Dework Foundry

Dework is a Foundry-based Solidity project for a freelance work marketplace. It includes smart contracts for freelancer and employer profiles, job listings, hiring, escrow funding, and releasing payments with a late-delivery penalty.

Repository: https://github.com/kshitijofficial/dework-foundry

## Project Structure

- `src/` - Solidity contracts and shared types.
- `test/` - Foundry tests for profile registration, job creation, hiring, and escrow payment release.
- `script/` - Foundry deployment script for the `Dework` contract.
- `app/` - Vite React frontend for interacting with the contract.

## Branches

- `master` - Base Foundry smart contract project with core `Dework` contract tests, including payment release deadline coverage.
- `refactor` - Refactored Solidity implementation and tests with cleaner contract structure and updated behavior.
- `dework-dapp` - Current dapp branch with frontend contract read/write integration and updated `App.jsx`/CSS.

## Smart Contract Features

- Register freelancer profiles.
- Register employer profiles.
- Create funded job listings.
- Hire freelancers for jobs.
- Release escrow payments.
- Apply a daily late-payment penalty after the deadline.
- Allow employer escrow withdrawals.
- Allow owner updates.

## Requirements

- Foundry
- Node.js and npm, for the frontend in `app/`

## Foundry Commands

Build contracts:

```shell
forge build
```

Run tests:

```shell
forge test
```

Format Solidity:

```shell
forge fmt
```

Run the deployment script locally:

```shell
forge script script/Dework.s.sol:DeworkScript
```

## Frontend Commands

From the `app/` directory:

```shell
npm install
npm run dev
```

Build the frontend:

```shell
npm run build
```

Run frontend linting:

```shell
npm run lint
```

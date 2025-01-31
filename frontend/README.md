# Introduction to Onchain Web Apps

This is a [Next.js](https://nextjs.org) project bootstrapped with `npm create onchain`.


## Getting Started

Install dependencies

```bash
npm install
```

Run the development server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

## API Transactions

The `POST /sessions` API route requires a `PRIVATE_KEY` environment variable that represents a wallet funded with ETH on Base Sepolia. Generating a fresh keypair for this account is recommended with the `cast wallet new` command from [Foundry](https://book.getfoundry.sh/).

## Learn More

* [OnchainKit](https://onchainkit.xyz)
* [Next.js](https://nextjs.org/docs)
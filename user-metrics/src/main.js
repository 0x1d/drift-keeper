require('dotenv').config()
const web3 = require("@solana/web3.js");
const drift = require("@drift-labs/sdk");
const express = require('express');
const { createMetrics } = require('./metrics');


const LAMPORTS_PER_SOL = 1000000000;

const USDC_INT = 1000000;

const USDC_MARKET = 0;
const SOL_MARKET = 1;

const SOL_MINT_ADDRESS = 'So11111111111111111111111111111111111111112';
const USDC_MINT_ADDRESS = 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v';

const USDC_MINT_PUBLIC_KEY = new web3.PublicKey(USDC_MINT_ADDRESS);
const keyPairFile = process.env.PRIVATE_KEY || process.env.PRIVATE_KEY_FILE;
const wallet = new drift.Wallet(drift.loadKeypair(keyPairFile));
const connection = new web3.Connection(process.env.RPC_ENDPOINT);

const [registry, metrics] = createMetrics();

const app = express();

const driftClient = new drift.DriftClient({
    connection,
    wallet,
    env: 'mainnet-beta',
    activeSubAccountId: 0,
    subAccountIds: [0],
});

const log = (msg) => {
    console.log(`[${new Date().toISOString()}] ${msg}`)
};

const trimWalletAddress = (walletAddress) => {
    return `${walletAddress.slice(0,4)}...${walletAddress.slice(walletAddress.length-4, walletAddress.length)}`;
}


const quoteNumber = (val) => {
    return drift.convertToNumber(val, drift.QUOTE_PRECISION);
}

const baseNumber = (val) => {
    return drift.convertToNumber(val, drift.BASE_PRECISION);
}

const getWalletBalance = async (connection, publicKey) => {
    const lamportsBalance = await connection.getBalance(publicKey);
    return lamportsBalance / LAMPORTS_PER_SOL;
};

const getUsdcBalance = async (connection, publicKey) => {
    const balance = await connection.getParsedTokenAccountsByOwner(
        publicKey, { mint: USDC_MINT_PUBLIC_KEY }
    );
    return balance.value[0]?.account.data.parsed.info.tokenAmount.uiAmount;
};

const init = async() => {
    await driftClient.subscribe();
    log('DriftClient initialized');
    ready = true;
};

let ready = false;

app.get('/metrics', async (req, res) => {
    res.setHeader('Content-Type', registry.contentType);
    registry.resetMetrics();

    if(ready){
        let user = driftClient.getUser();
        let label = { wallet: wallet.publicKey.toString(), walletShort: trimWalletAddress(wallet.publicKey.toString()) };
    
        metrics.totalCollateral.set(label, quoteNumber(user.getTotalCollateral()));
        metrics.unrealizedPNL.set(label, quoteNumber(user.getUnrealizedPNL()));
        metrics.solBalance.set(label, await getWalletBalance(connection, wallet.publicKey));
        metrics.usdcBalance.set(label, await getUsdcBalance(connection, wallet.publicKey));
    }

    res.send(await registry.metrics());

});

app.listen(3000, () => {
    log("Server is running on port 3000");
    init();
});


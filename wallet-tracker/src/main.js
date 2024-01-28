const express = require('express');
const { createMetrics } = require('./metrics');
const { loadWalletBalance, loadUSDCBalance, extractWalletBalance, extractUSDCBalance } = require('./solana');

const WALLET_ADDRESS = process.env.WALLET_ADDRESS;
const [registry, usdcBalanceMetric, solBalanceMetric] = createMetrics();
const app = express();

app.get('/metrics', async (req, res) => {
    res.setHeader('Content-Type', registry.contentType);

    let [solBalance, usdcBalance] = await Promise.all([
        loadWalletBalance(WALLET_ADDRESS),
        loadUSDCBalance(WALLET_ADDRESS)]);

    solBalanceMetric.set(extractWalletBalance(solBalance));
    usdcBalanceMetric.set(extractUSDCBalance(usdcBalance));

    res.send(await registry.metrics());
});

app.listen(3000, () => {
    console.log("Server is running on port 3000");
});

const express = require('express');
const { createMetrics } = require('./metrics');
const { loadWalletBalance, loadUSDCBalance, loadSolanaMarketData, extractWalletBalance, extractUSDCBalance, extractSOLPrice } = require('./solana');

const WALLET_ADDRESS = process.env.WALLET_ADDRESS;
const [registry, usdcBalanceMetric, solBalanceMetric, solUsdcBalanceMetric] = createMetrics();
const app = express();

app.get('/metrics', async (req, res) => {
    res.setHeader('Content-Type', registry.contentType);

    let [solBalance, usdcBalance, marketData] = await Promise.all([
        loadWalletBalance(WALLET_ADDRESS),
        loadUSDCBalance(WALLET_ADDRESS),
        loadSolanaMarketData()]);

    solBalanceMetric.set({ wallet: WALLET_ADDRESS}, extractWalletBalance(solBalance));
    usdcBalanceMetric.set({ wallet: WALLET_ADDRESS}, extractUSDCBalance(usdcBalance));
    solUsdcBalanceMetric.set({ wallet: WALLET_ADDRESS}, extractWalletBalance(solBalance) * extractSOLPrice(marketData));
    
    res.send(await registry.metrics());
});

app.listen(3000, () => {
    console.log("Server is running on port 3000");
});

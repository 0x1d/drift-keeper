const express = require('express');
const { createMetrics } = require('./metrics');
const { loadWalletBalance, loadUSDCBalance, loadSolanaMarketData, extractWalletBalance, extractUSDCBalance, extractSOLPrice } = require('./solana');

const WALLET_ADDRESS = process.env.WALLET_ADDRESS;
const [registry, usdcBalanceMetric, solBalanceMetric, solUsdcBalanceMetric] = createMetrics();
const app = express();

const trimWalletAddress = (walletAddress) => {
    return `${walletAddress.slice(0,4)}...${walletAddress.slice(walletAddress.length-4, walletAddress.length)}`;
}

app.get('/metrics/:addr?', async (req, res) => {
    const walletAddress = req.params.addr || WALLET_ADDRESS;
    console.log(`Gathering metrics for ${walletAddress}`);
    res.setHeader('Content-Type', registry.contentType);
    
    registry.resetMetrics();

    let [solBalance, usdcBalance, marketData] = await Promise.all([
        loadWalletBalance(walletAddress),
        loadUSDCBalance(walletAddress),
        loadSolanaMarketData()]);

    let label = { wallet: walletAddress, walletShort: trimWalletAddress(walletAddress) };

    solBalanceMetric.set(label, extractWalletBalance(solBalance));
    usdcBalanceMetric.set(label, extractUSDCBalance(usdcBalance));
    solUsdcBalanceMetric.set(label, extractWalletBalance(solBalance) * extractSOLPrice(marketData));

    res.send(await registry.metrics());
});

app.listen(3000, () => {
    console.log("Server is running on port 3000");
});
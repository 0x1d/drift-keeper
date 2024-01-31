const LAMPORTS_PER_SOL = 1000000000;
const SOLANA_RPC = "https://api.mainnet-beta.solana.com/";
const JUPITER_PRICE_API = "https://price.jup.ag/v4/price?ids=SOL"

const rpcRequestHeaders = {
    "Content-Type": "application/json",
};
const rpcRequest = (method, params) => {
    return {
        jsonrpc: "2.0",
        id: 1,
        method: method,
        params: params,
    };
};

// POST request to Solana API to load wallet balance
async function loadWalletBalance(walletAddress) {
    const response = await fetch(SOLANA_RPC, {
        method: "POST",
        headers: rpcRequestHeaders,
        body: JSON.stringify(rpcRequest("getBalance", [walletAddress])),
    });
    const json = await response.json();
    return json;
}

// POST request to Solana API to load USDC balance
async function loadUSDCBalance(walletAddress) {
    const response = await fetch(SOLANA_RPC, {
        method: "POST",
        headers: rpcRequestHeaders,
        body: JSON.stringify(
            rpcRequest("getTokenAccountsByOwner", [
                walletAddress,
                { "mint": "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v" },
                { "encoding": "jsonParsed" }])
        ),
    });
    const json = await response.json();
    return json;
}

async function loadSolanaMarketData() {
    const response = await fetch(JUPITER_PRICE_API);
    const json = await response.json();
    return json;
}

// extract wallet balance
function extractWalletBalance(walletBalance) {
    return walletBalance.result.value / LAMPORTS_PER_SOL;
}

// extract USDC balance
function extractUSDCBalance(usdcBalance) {
    return usdcBalance.result.value[0].account.data.parsed.info.tokenAmount.uiAmount;
}

// extract SOL price
function extractSOLPrice(marketData) {
    return marketData.data.SOL.price;
}

// export functions
module.exports = {
    loadWalletBalance,
    loadUSDCBalance,
    loadSolanaMarketData,
    extractWalletBalance,
    extractUSDCBalance,
    extractSOLPrice
};
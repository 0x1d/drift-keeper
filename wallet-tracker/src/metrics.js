const client = require('prom-client');

const createMetrics = () => {
    const registry = new client.Registry();

    const solBalanceMetric = new client.Gauge({
        name: "sol_balance",
        help: "SOL Balance",
        labelNames: ['wallet','walletShort']
    });
    const usdcBalanceMetric = new client.Gauge({
        name: "usdc_balance",
        help: "USDC Balance",
        labelNames: ['wallet','walletShort']
    });
    const solUsdcBalanceMetric = new client.Gauge({
        name: "sol_usdc_balance",
        help: "SOL Balance in USDC",
        labelNames: ['wallet','walletShort']
    });

    const solPriceMetric = new client.Gauge({
        name: "sol_price",
        help: "SOL Price in USDC"
    });

    registry.registerMetric(usdcBalanceMetric);
    registry.registerMetric(solBalanceMetric);
    registry.registerMetric(solUsdcBalanceMetric);
    registry.registerMetric(solPriceMetric);

    return [registry, usdcBalanceMetric, solBalanceMetric, solUsdcBalanceMetric, solPriceMetric];
};

module.exports = {
    createMetrics
}

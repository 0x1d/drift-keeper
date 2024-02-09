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

    registry.registerMetric(usdcBalanceMetric);
    registry.registerMetric(solBalanceMetric);
    registry.registerMetric(solUsdcBalanceMetric);

    return [registry, usdcBalanceMetric, solBalanceMetric, solUsdcBalanceMetric];
};

module.exports = {
    createMetrics
}
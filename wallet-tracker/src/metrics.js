const client = require('prom-client');

const createMetrics = () => {
    const registry = new client.Registry();

    const solBalanceMetric = new client.Gauge({
        name: "sol_balance",
        help: "SOL Balance",
    });
    const usdcBalanceMetric = new client.Gauge({
        name: "usdc_balance",
        help: "USDC Balance",
    });

    registry.registerMetric(usdcBalanceMetric);
    registry.registerMetric(solBalanceMetric);

    return [registry, usdcBalanceMetric, solBalanceMetric];
};

module.exports = {
    createMetrics
}
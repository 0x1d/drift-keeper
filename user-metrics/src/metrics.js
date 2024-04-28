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
    const totalCollateralMetric = new client.Gauge({
        name: "total_collateral",
        help: "Total Collateral",
        labelNames: ['wallet','walletShort']
    });
    const unrealizedPNLMetric = new client.Gauge({
        name: "unrealized_pnl",
        help: "Unrealized PNL",
        labelNames: ['wallet','walletShort']
    });

    registry.registerMetric(usdcBalanceMetric);
    registry.registerMetric(solBalanceMetric);
    registry.registerMetric(totalCollateralMetric);
    registry.registerMetric(unrealizedPNLMetric);

    return [registry, {
        usdcBalance: usdcBalanceMetric, 
        solBalance: solBalanceMetric,
        totalCollateral: totalCollateralMetric,
        unrealizedPNL: unrealizedPNLMetric
    }];
};

module.exports = {
    createMetrics
}

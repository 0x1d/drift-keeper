global:
  # devnet or mainnet-beta
  driftEnv: mainnet-beta

  # RPC endpoint to use
  endpoint:

  # Custom websocket endpoint to use (if null will be determined from `endpoint``)
  # Note: the default wsEndpoint value simply replaces http(s) with ws(s), so if
  #       your RPC provider requires a special path (i.e. /ws) for websocket connections
  #       you must set this.
  wsEndpoint:

  # optional if you want to use helius' global priority fee method AND `endpoint` is not
  # already a helius url.
  heliusEndpoint:

  # `solana` or `helius`. If `helius` `endpoint` must be a helius RPC, or `heliusEndpoint`
  #   must be set
  # solana: uses https://solana.com/docs/rpc/http/getrecentprioritizationfees
  # helius: uses https://docs.helius.dev/solana-rpc-nodes/alpha-priority-fee-api
  priorityFeeMethod: solana

  # skips preflight checks on sendTransaciton, default is false.
  # this will speed up tx sending, but may increase SOL paid due to failed txs landing
  # on chain
  txSkipPreflight: false

  # max priority fee to use, in micro lamports
  # i.e. a fill that uses 500_000 CUs will spend:
  # 500_000 * 10_000 * 1e-6 * 1e-9 = 0.000005 SOL on priority fees
  # this is on top of the 0.000005 SOL base fee, so 0.000010 SOL total
  maxPriorityFeeMicroLamports: 10000

  # Private key to use to sign transactions.
  # will load from KEEPER_PRIVATE_KEY env var if null
  keeperPrivateKey:

  initUser: false # initialize user on startup
  testLiveness: false # test liveness, by failing liveness test after 1 min

  # Force deposit this amount of USDC to collateral account, the program will
  # end after the deposit transaction is sent
  #forceDeposit: 1000

  websocket: true  # use websocket for account loading and events (limited support)
  eventSubscriber: false # disables event subscriber (heavy RPC demand), this is primary used for counting fills
  runOnce: false # Set true to run once and exit, useful for testing or one off bot runs
  debug: false # Enable debug logging
  txSenderType: "fast"
  
  # subaccountIDs to load, if null will load subaccount 0 (default).
  # Even if bot specific configs requires subaccountIDs, you should still
  # specify it here, since we load the subaccounts before loading individual
  # bots.
  # subaccounts:
  # - 0
  # - 1
  # - 2

  eventSubscriberPollingInterval: 5000
  bulkAccountLoaderPollingInterval: 5000

  useJito: ${use_jito}
  # one of: ['non-jito-only', 'jito-only', 'hybrid'].
  # * non-jito-only: will only send txs to RPC when there is no active jito leader
  # * jito-only: will only send txs via bundle when there is an active jito leader
  # * hybrid: will attempt to send bundles when active jito leader, and use RPC when not
  # hybrid may not work well if using high throughput bots such as a filler depending on infra limitations.
  jitoStrategy: jito-only
  # the minimum tip to pay
  jitoMinBundleTip: 10000
  # the maximum tip to pay (will pay this once jitoMaxBundleFailCount is hit)
  jitoMaxBundleTip: 100000
  # the number of failed bundles (accepted but not landed) before tipping the max tip
  jitoMaxBundleFailCount: 200
  # the tip multiplier to use when tipping the max tip
  # controls superlinearity (1 = linear, 2 = slightly-superlinear, 3 = more-superlinear, ...)
  jitoTipMultiplier: 3
  jitoBlockEngineUrl:
  jitoAuthPrivateKey:

  # which subaccounts to load, if null will load subaccount 0 (default)
  subaccounts:

#  perpMarketIndexes:
#    - 1

# Which bots to run, be careful with this, running multiple bots in one instance
# might use more resources than expected.
# Bot specific configs are below
enabledBots:
  # Perp order filler bot
  - fillerLite

  # Spot order filler bot
  #- spotFiller

  # Trigger bot (triggers trigger orders)
  #- trigger
  
  # Liquidator bot, liquidates unhealthy positions by taking over the risk (caution, you should manage risk here)
  # - liquidator

  # Example maker bot that participates in JIT auction (caution: you will probably lose money)
  # - jitMaker

  # Example maker bot that posts floating oracle orders
  #- floatingMaker

  # settles PnLs for the insurance fund (may want to run with runOnce: true)
  # - ifRevenueSettler

  # settles negative PnLs for users (may want to run with runOnce: true)
  # - userPnlSettler

  # - markTwapCrank

  # below are bot configs
botConfigs:

  fillerLite:
    botId: "fillerLite"
    dryRun: false
    fillerPollingInterval: 6000
    metricsPort: 9464
    revertOnFailure: true
    simulateTxForCUEstimate: true

  filler:
    botId: "filler"
    dryRun: false
    fillerPollingInterval: 6000
    metricsPort: 9464

    # will revert a transaction during simulation if a fill fails, this will save on tx fees,
    # and be friendlier for use with services like Jito.
    # Default is true
    revertOnFailure: true

    # calls simulateTransaction before sending to get an accurate CU estimate
    # as well as stop before sending the transaction (Default is true)
    simulateTxForCUEstimate: true

  spotFiller:
    botId: "spot-filler"
    dryRun: false
    fillerPollingInterval: 6000
    metricsPort: 9465
    revertOnFailure: true
    simulateTxForCUEstimate: true

  liquidator:
    botId: "liquidator"
    dryRun: false
    metricsPort: 9466
    # if true will NOT attempt to sell off any inherited positions
    disableAutoDerisking: false
    # if true will swap spot assets on jupiter if the price is better
    useJupiter: true
    # null will handle all markets
    perpMarketIndicies:
    spotMarketIndicies:

    # this replaces perpMarketIndicies and spotMarketIndicies by allowing you to specify
    # which subaccount is responsible for liquidating markets
    # Markets are defined on perpMarkets.ts and spotMarkets.ts on the protocol codebase
    # Note: you must set global.subaccounts with all the subaccounts you want to load
    perpSubAccountConfig:
      0:
        # subaccount 0 will watch perp markets 0 and 1
        - 0
        - 1
    spotSubAccountConfig:
      0:
        # subaccount 0 will watch all spot markets

        # max slippage (from oracle price) to incur allow when derisking
    maxSlippagePct: 0.05

    # what algo to use for derisking. Options are "market" or "twap"
    deriskAlgo: "market"

    # if deriskAlgo == "twap", must supply these as well
    # twapDurationSec: 300 # overall duration of to run the twap algo. Aims to derisk the entire position over this duration

    # Minimum deposit amount to try to liquidiate, per spot market, in lamports.
    # If null, or a spot market isn't here, it will liquidate any amount
    # See perpMarkets.ts on the protocol codebase for the indices
    minDepositToLiq:
      1: 10
      2: 1000

    # Filter out un-liquidateable accounts that just create log noise
    excludedAccounts:
      - 9CJLgd5f9nmTp7KRV37RFcQrfEmJn6TU87N7VQAe2Pcq
      - Edh39zr8GnQFNYwyvxhPngTJHrr29H3vVup8e8ZD4Hwu

    # max % of collateral to spend when liquidating a user. In percentage terms (0.5 = 50%)
    maxPositionTakeoverPctOfCollateral: 0.5

    # sends a webhook notification (slack, discord, etc.) when a liquidation is attempted (can be noisy due to partial liquidations)
    notifyOnLiquidation: true

  trigger:
    botId: "trigger"
    dryRun: false
    metricsPort: 9465

  markTwapCrank:
    botId: "mark-twap-cranker"
    dryRun: false
    metricsPort: 9465
    crankIntervalToMarketIndicies:
      15000:
        - 0
        - 1
        - 2
      60000:
        - 3
        - 4
        - 5
        - 6
        - 7
        - 8
        - 9
        - 10
        - 11
        - 12
        - 13
        - 14
        - 15
        - 16

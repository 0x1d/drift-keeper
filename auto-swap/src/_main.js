require('dotenv').config()
const web3 = require("@solana/web3.js");
const drift = require("@drift-labs/sdk");

const LAMPORTS_PER_SOL = 1000000000;
const AUTOSWAP_INTERVAL = process.env.AUTOSWAP_INTERVAL || 1000 * 60;

const USDC_MARKET = 0;
const SOL_MARKET = 1;

const SWAP_RATIO = process.env.SWAP_RATIO || 0.5;
const SWAP_THRESHOLD = process.env.SWAP_THRESHOLD || 10;

const USDC_INT = 1000000;

const SOL_MINT_ADDRESS = 'So11111111111111111111111111111111111111112';
const USDC_MINT_ADDRESS = 'EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v';

const USDC_MINT_PUBLIC_KEY = new web3.PublicKey(USDC_MINT_ADDRESS);
const keyPairFile = process.env.PRIVATE_KEY || process.env.PRIVATE_KEY_FILE;
const wallet = new drift.Wallet(drift.loadKeypair(keyPairFile));
const connection = new web3.Connection(process.env.RPC_ENDPOINT);

const thresholdReached = (amount) => amount / USDC_INT > SWAP_THRESHOLD;

const driftClient = new drift.DriftClient({
    connection,
    wallet,
    env: 'mainnet-beta',
    activeSubAccountId: 0,
    subAccountIds: [0],
});

const sleep = (ms) => {
    return new Promise(resolve => setTimeout(resolve, ms));
}

const log = (msg) => {
    console.log(`[${new Date().toISOString()}] ${msg}`)
};

const quoteNumber = (val) => {
    return drift.convertToNumber(val, drift.QUOTE_PRECISION);
}

const baseNumber = (val) => {
    return drift.convertToNumber(val, drift.BASE_PRECISION);
}

const quoteUsdcSol = async (amount) => {
    const quoteUrl = `https://quote-api.jup.ag/v6/quote?inputMint=${USDC_MINT_ADDRESS}&outputMint=${SOL_MINT_ADDRESS}&amount=${amount}&slippageBps=50`;
    const quoteResponse = await (
        await fetch(quoteUrl)
    ).json();
    return quoteResponse;
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

const printInfo = async (user) => {
    let usdcInAccount = quoteNumber(user.getTokenAmount(USDC_MARKET));
    let solInWallet = await getWalletBalance(connection, wallet.publicKey);
    let usdcWallet = await getUsdcBalance(connection, wallet.publicKey)

    log(`USDC in account: ${usdcInAccount}`);
    log(`USDC in wallet: ${usdcWallet}`);
    log(`SOL in wallet: ${solInWallet}`);
};

const calcSwapAmount = (usdcInAccount) => {
    return usdcInAccount * SWAP_RATIO;
};

const getSerializedTransaction = async (quote) => {
    return await (
        await fetch('https://quote-api.jup.ag/v6/swap', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                quoteResponse: quote,
                userPublicKey: wallet.publicKey.toString(),
                wrapAndUnwrapSol: true,
                dynamicComputeUnitLimit: true, // allow dynamic compute limit instead of max 1,400,000
                prioritizationFeeLamports: 'auto' // capped at 5,000,000 lamports / 0.005 SOL.
            })
        })
    ).json();
};

const signTransaction = (swapTransaction) => {
    const swapTransactionBuf = Buffer.from(swapTransaction, 'base64');
    var transaction = web3.VersionedTransaction.deserialize(swapTransactionBuf);
    transaction.sign([wallet.payer]);
    return transaction;
};

const sendTransaction = async (transaction) => {
    const rawTransaction = transaction.serialize()
    return connection.sendRawTransaction(rawTransaction, {
        skipPreflight: false,
        preflightCommitment: 'confirmed',
        // Maximum number of times for the RPC node to retry sending the transaction to the leader. 
        // If this parameter is not provided, the RPC node will retry the transaction until it is finalized or until the blockhash expires.
        //maxRetries: 0
    })

};

const withdraw = async (marketIndex, withdrawAmount) => {
    const amount = driftClient.convertToSpotPrecision(marketIndex, withdrawAmount);
    const associatedTokenAccount = await driftClient.getAssociatedTokenAccount(marketIndex);
    const reduceOnly = true;
    return driftClient.withdraw(
        amount,
        marketIndex,
        associatedTokenAccount,
        reduceOnly
    );
};

const signAndSendTx = async (quote) => {
    let tx = await getSerializedTransaction(quote);
    let signedTx = signTransaction(tx.swapTransaction);
    return sendTransaction(signedTx);
};

const confirmTx = async (txSig) => {
    const latestBlockHash = await connection.getLatestBlockhash();
    return connection.confirmTransaction({
        blockhash: latestBlockHash.blockhash,
        lastValidBlockHeight: latestBlockHash.lastValidBlockHeight,
        signature: txSig,
    }, 'confirmed');
};

const run2 = async () => {

    await driftClient.subscribe();
    const user = driftClient.getUser();
    
    // force markets to be included
    driftClient.perpMarketLastSlotCache.set(SOL_MARKET, Number.MAX_SAFE_INTEGER);
    driftClient.perpMarketLastSlotCache.set(USDC_MARKET, Number.MAX_SAFE_INTEGER);

    log('---------------------------------')
    log("DriftClient initialized")
    log(`Swap Ratio: ${SWAP_RATIO}`);
    log(`Swap Threshold: ${SWAP_THRESHOLD} USDC`);
    printInfo(user);

    let swapInProgress = false;

    let lastUsdcInAccount = await connection.getBalance(publicKey);
    let lastSolInWallet = await getWalletBalance(connection, wallet.publicKey);

    setInterval(async () => {
        if (!swapInProgress) {
            let currentUsdcInAccount = await connection.getBalance(publicKey);
            let currentSolInWallet = await getWalletBalance(connection, wallet.publicKey);

            let differenceSol = lastSolInWallet - currentSolInWallet;
            let differenceUsdc = currentUsdcInAccount - lastUsdcInAccount;

            await quoteUsdcSol(differenceUsdc)
                .then(quote => {
                    log(`Swap: ${differenceUsdc / USDC_INT}$ to ${quote.outAmount / LAMPORTS_PER_SOL} SOL`);
                    //return signAndSendTx(quote);
                })
            lastUsdcInAccount = currentUsdcInAccount;
        }
    }, AUTOSWAP_INTERVAL);
};

const run = async () => {

    await driftClient.subscribe();
    const user = driftClient.getUser();
    
    // force markets to be included
    driftClient.perpMarketLastSlotCache.set(SOL_MARKET, Number.MAX_SAFE_INTEGER);
    driftClient.perpMarketLastSlotCache.set(USDC_MARKET, Number.MAX_SAFE_INTEGER);

    log('---------------------------------')
    log("DriftClient initialized")
    log(`Swap Ratio: ${SWAP_RATIO}`);
    log(`Swap Threshold: ${SWAP_THRESHOLD} USDC`);
    printInfo(user);

    let swapInProgress = false;

    setInterval(async () => {
        if (!swapInProgress) {
            try {
                let usdcInAccount = user.getTokenAmount(USDC_MARKET);
                let swapAmount = Math.floor(calcSwapAmount(usdcInAccount));

                if (thresholdReached(usdcInAccount)) {
                    log('---------------------------------')
                    printInfo(user);
                    swapInProgress = true;

                    let withdrawSuccessful = false;
                    let withdrawRetries = 0;
                    let maxWithdrawRetries = 3;
                    while (!withdrawSuccessful && withdrawRetries < maxWithdrawRetries) {
                        log(`Withdraw from exchange`);
                        await withdraw(USDC_MARKET, quoteNumber(user.getTokenAmount(USDC_MARKET)))
                            .then(async (txSig) => {
                                log(`Confirm withdraw: https://solscan.io/tx/${txSig}`);
                                return confirmTx(txSig);
                            }, (error) => {
                                throw `Withdraw TX failed: ${error}`;
                            })
                            .then((confirmResult) => {
                                if (confirmResult.value.err) {
                                    throw `Withdraw not confirmed`;
                                } else {
                                    log(`Withdraw confirmed`);
                                    withdrawSuccessful = true;
                                }
                            })
                            .catch(error => {
                                withdrawRetries++;
                                log(`Withdraw failed (${withdrawRetries}/${maxWithdrawRetries}): ${error}`);
                                // TODO check if withdraw was still somehow successfull
                                // it sometimes happens and we're then stuck in the loop
                            });
                    }

                    //backoff & try again in next iteration
                    if (withdrawRetries === maxWithdrawRetries) {
                        log('Withdraw failed - check if account balance changed and the withdraw actualy did not fail');
                        let currentUsdcInAccount = user.getTokenAmount(USDC_MARKET);
                        if(currentUsdcInAccount < usdcInAccount) {
                            log('Withdraw seemed to went through - continue with swap');
                        } else {
                            log('Withdraw really failed - backoff & try again in next iteration');
                            swapInProgress = false;
                            return;
                        }
                    }

                    let swapSuccessful = false
                    let swapRetries = 0;
                    let maxSwapRetries = 3;
                    while (!swapSuccessful && swapRetries < maxSwapRetries) {
                        // TODO calculate fresh swapAmount every iteration as collateral may has increased in the mean time
                        await quoteUsdcSol(swapAmount)
                            .then(quote => {
                                log(`Swap: ${swapAmount / USDC_INT}$ to ${quote.outAmount / LAMPORTS_PER_SOL} SOL`);
                                return signAndSendTx(quote);
                            })
                            .then(async txSig => {
                                log(`Confirm swap: https://solscan.io/tx/${txSig}`);
                                return confirmTx(txSig);
                            })
                            .then(confirmResult => {
                                if (confirmResult.value.err) {
                                    throw `Confirm swap failed ${confirmResult.value.err}`;
                                } else {
                                    log('Swap successful')
                                    log('---------------------------------')
                                    swapInProgress = false;
                                    swapSuccessful = true;
                                }
                            })
                            .catch(error => {
                                swapRetries++;
                                log(`FAAAAAIL (${swapRetries}/${maxSwapRetries}): ${error}`);
                            })
                        sleep(1000);
                    }

                    //backoff & try again in next iteration
                    if (swapRetries === maxSwapRetries) {
                        log('Swap failed - backoff & try again in next iteration');
                        swapInProgress = false;
                        return;
                    }



                } else {
                    log(`Waiting to reach threshold - current balance on DEX: ${usdcInAccount / USDC_INT} USDC`);
                    swapInProgress = false;
                }
            } catch (error) {
                log(error);
                swapInProgress = false;
            }
        } else {
            log('Swap in progress')
        }
    }, AUTOSWAP_INTERVAL);

};

run2();

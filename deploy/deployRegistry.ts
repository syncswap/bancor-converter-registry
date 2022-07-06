import { utils, Wallet } from "zksync-web3";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";

import * as secrets from "../secrets.json";

const feeToken: string | undefined = '';

export default async function (hre: HardhatRuntimeEnvironment) {
    // Initialize deployer.
    const wallet = new Wallet(secrets.privateKey);
    const deployer = new Deployer(hre, wallet);
    console.log(`Use account ${wallet.address} as deployer.`);

    console.log(`Deploying BancorConverterRegistry contract..`);
    const artifact = await deployer.loadArtifact('BancorConverterRegistry');
    const registryContract = await deployer.deploy(artifact, [], feeToken ? {
        feeToken: feeToken
    } : undefined);

    await registryContract.deployed();
    console.log(`BancorConverterRegistry has been successfully deployed to ${registryContract.address}.`);
}

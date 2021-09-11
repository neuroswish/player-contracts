/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { ethers } from "ethers";
import {
  FactoryOptions,
  HardhatEthersHelpers as HardhatEthersHelpersBase,
} from "@nomiclabs/hardhat-ethers/types";

import * as Contracts from ".";

declare module "hardhat/types/runtime" {
  interface HardhatEthersHelpers extends HardhatEthersHelpersBase {
    getContractFactory(
      name: "BondingCurve",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.BondingCurve__factory>;
    getContractFactory(
      name: "Cryptomedia",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Cryptomedia__factory>;
    getContractFactory(
      name: "CryptomediaFactory",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.CryptomediaFactory__factory>;
    getContractFactory(
      name: "IBondingCurve",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.IBondingCurve__factory>;
    getContractFactory(
      name: "Power",
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<Contracts.Power__factory>;

    // default types
    getContractFactory(
      name: string,
      signerOrOptions?: ethers.Signer | FactoryOptions
    ): Promise<ethers.ContractFactory>;
    getContractFactory(
      abi: any[],
      bytecode: ethers.utils.BytesLike,
      signer?: ethers.Signer
    ): Promise<ethers.ContractFactory>;
  }
}

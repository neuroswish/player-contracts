/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import {
  ethers,
  EventFilter,
  Signer,
  BigNumber,
  BigNumberish,
  PopulatedTransaction,
  BaseContract,
  ContractTransaction,
  Overrides,
  PayableOverrides,
  CallOverrides,
} from "ethers";
import { BytesLike } from "@ethersproject/bytes";
import { Listener, Provider } from "@ethersproject/providers";
import { FunctionFragment, EventFragment, Result } from "@ethersproject/abi";
import { TypedEventFilter, TypedEvent, TypedListener } from "./commons";

interface MarketInterface extends ethers.utils.Interface {
  functions: {
    "addLayer(string)": FunctionFragment;
    "addressToCuratedLayers(address,uint256)": FunctionFragment;
    "addressToLayer(address)": FunctionFragment;
    "balanceOf(address)": FunctionFragment;
    "bondingCurve()": FunctionFragment;
    "buy(uint256,uint256)": FunctionFragment;
    "created(address)": FunctionFragment;
    "curate(address)": FunctionFragment;
    "initialize(string,address)": FunctionFragment;
    "isCuratingLayer(address,address)": FunctionFragment;
    "layers(uint256)": FunctionFragment;
    "name()": FunctionFragment;
    "poolBalance()": FunctionFragment;
    "ppm()": FunctionFragment;
    "removeCuration(address)": FunctionFragment;
    "removeLayer()": FunctionFragment;
    "reserveRatio()": FunctionFragment;
    "sell(uint256,uint256)": FunctionFragment;
    "totalSupply()": FunctionFragment;
  };

  encodeFunctionData(functionFragment: "addLayer", values: [string]): string;
  encodeFunctionData(
    functionFragment: "addressToCuratedLayers",
    values: [string, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "addressToLayer",
    values: [string]
  ): string;
  encodeFunctionData(functionFragment: "balanceOf", values: [string]): string;
  encodeFunctionData(
    functionFragment: "bondingCurve",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "buy",
    values: [BigNumberish, BigNumberish]
  ): string;
  encodeFunctionData(functionFragment: "created", values: [string]): string;
  encodeFunctionData(functionFragment: "curate", values: [string]): string;
  encodeFunctionData(
    functionFragment: "initialize",
    values: [string, string]
  ): string;
  encodeFunctionData(
    functionFragment: "isCuratingLayer",
    values: [string, string]
  ): string;
  encodeFunctionData(
    functionFragment: "layers",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(functionFragment: "name", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "poolBalance",
    values?: undefined
  ): string;
  encodeFunctionData(functionFragment: "ppm", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "removeCuration",
    values: [string]
  ): string;
  encodeFunctionData(
    functionFragment: "removeLayer",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "reserveRatio",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "sell",
    values: [BigNumberish, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "totalSupply",
    values?: undefined
  ): string;

  decodeFunctionResult(functionFragment: "addLayer", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "addressToCuratedLayers",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "addressToLayer",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "balanceOf", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "bondingCurve",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "buy", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "created", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "curate", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "initialize", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "isCuratingLayer",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "layers", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "name", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "poolBalance",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "ppm", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "removeCuration",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "removeLayer",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "reserveRatio",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "sell", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "totalSupply",
    data: BytesLike
  ): Result;

  events: {
    "Approval(address,address,uint256)": EventFragment;
    "Buy(address,uint256,uint256,uint256,uint256)": EventFragment;
    "CurationAdded(address,address)": EventFragment;
    "CurationRemoved(address,address)": EventFragment;
    "LayerAdded(address,string)": EventFragment;
    "LayerRemoved(address)": EventFragment;
    "Sell(address,uint256,uint256,uint256,uint256)": EventFragment;
    "Transfer(address,address,uint256)": EventFragment;
  };

  getEvent(nameOrSignatureOrTopic: "Approval"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "Buy"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "CurationAdded"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "CurationRemoved"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "LayerAdded"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "LayerRemoved"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "Sell"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "Transfer"): EventFragment;
}

export class Market extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  listeners<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter?: TypedEventFilter<EventArgsArray, EventArgsObject>
  ): Array<TypedListener<EventArgsArray, EventArgsObject>>;
  off<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter: TypedEventFilter<EventArgsArray, EventArgsObject>,
    listener: TypedListener<EventArgsArray, EventArgsObject>
  ): this;
  on<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter: TypedEventFilter<EventArgsArray, EventArgsObject>,
    listener: TypedListener<EventArgsArray, EventArgsObject>
  ): this;
  once<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter: TypedEventFilter<EventArgsArray, EventArgsObject>,
    listener: TypedListener<EventArgsArray, EventArgsObject>
  ): this;
  removeListener<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter: TypedEventFilter<EventArgsArray, EventArgsObject>,
    listener: TypedListener<EventArgsArray, EventArgsObject>
  ): this;
  removeAllListeners<EventArgsArray extends Array<any>, EventArgsObject>(
    eventFilter: TypedEventFilter<EventArgsArray, EventArgsObject>
  ): this;

  listeners(eventName?: string): Array<Listener>;
  off(eventName: string, listener: Listener): this;
  on(eventName: string, listener: Listener): this;
  once(eventName: string, listener: Listener): this;
  removeListener(eventName: string, listener: Listener): this;
  removeAllListeners(eventName?: string): this;

  queryFilter<EventArgsArray extends Array<any>, EventArgsObject>(
    event: TypedEventFilter<EventArgsArray, EventArgsObject>,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TypedEvent<EventArgsArray & EventArgsObject>>>;

  interface: MarketInterface;

  functions: {
    addLayer(
      _URI: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    addressToCuratedLayers(
      arg0: string,
      arg1: BigNumberish,
      overrides?: CallOverrides
    ): Promise<[string, string] & { creator: string; URI: string }>;

    addressToLayer(
      arg0: string,
      overrides?: CallOverrides
    ): Promise<[string, string] & { creator: string; URI: string }>;

    balanceOf(arg0: string, overrides?: CallOverrides): Promise<[BigNumber]>;

    bondingCurve(overrides?: CallOverrides): Promise<[string]>;

    buy(
      _price: BigNumberish,
      _minTokensReturned: BigNumberish,
      overrides?: PayableOverrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    created(arg0: string, overrides?: CallOverrides): Promise<[boolean]>;

    curate(
      _creator: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    initialize(
      _name: string,
      _bondingCurve: string,
      overrides?: PayableOverrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    isCuratingLayer(
      arg0: string,
      arg1: string,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    layers(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<[string, string] & { creator: string; URI: string }>;

    name(overrides?: CallOverrides): Promise<[string]>;

    poolBalance(overrides?: CallOverrides): Promise<[BigNumber]>;

    ppm(overrides?: CallOverrides): Promise<[number]>;

    removeCuration(
      _creator: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    removeLayer(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    reserveRatio(overrides?: CallOverrides): Promise<[number]>;

    sell(
      _tokens: BigNumberish,
      _minETHReturned: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<ContractTransaction>;

    totalSupply(overrides?: CallOverrides): Promise<[BigNumber]>;
  };

  addLayer(
    _URI: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  addressToCuratedLayers(
    arg0: string,
    arg1: BigNumberish,
    overrides?: CallOverrides
  ): Promise<[string, string] & { creator: string; URI: string }>;

  addressToLayer(
    arg0: string,
    overrides?: CallOverrides
  ): Promise<[string, string] & { creator: string; URI: string }>;

  balanceOf(arg0: string, overrides?: CallOverrides): Promise<BigNumber>;

  bondingCurve(overrides?: CallOverrides): Promise<string>;

  buy(
    _price: BigNumberish,
    _minTokensReturned: BigNumberish,
    overrides?: PayableOverrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  created(arg0: string, overrides?: CallOverrides): Promise<boolean>;

  curate(
    _creator: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  initialize(
    _name: string,
    _bondingCurve: string,
    overrides?: PayableOverrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  isCuratingLayer(
    arg0: string,
    arg1: string,
    overrides?: CallOverrides
  ): Promise<boolean>;

  layers(
    arg0: BigNumberish,
    overrides?: CallOverrides
  ): Promise<[string, string] & { creator: string; URI: string }>;

  name(overrides?: CallOverrides): Promise<string>;

  poolBalance(overrides?: CallOverrides): Promise<BigNumber>;

  ppm(overrides?: CallOverrides): Promise<number>;

  removeCuration(
    _creator: string,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  removeLayer(
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  reserveRatio(overrides?: CallOverrides): Promise<number>;

  sell(
    _tokens: BigNumberish,
    _minETHReturned: BigNumberish,
    overrides?: Overrides & { from?: string | Promise<string> }
  ): Promise<ContractTransaction>;

  totalSupply(overrides?: CallOverrides): Promise<BigNumber>;

  callStatic: {
    addLayer(_URI: string, overrides?: CallOverrides): Promise<boolean>;

    addressToCuratedLayers(
      arg0: string,
      arg1: BigNumberish,
      overrides?: CallOverrides
    ): Promise<[string, string] & { creator: string; URI: string }>;

    addressToLayer(
      arg0: string,
      overrides?: CallOverrides
    ): Promise<[string, string] & { creator: string; URI: string }>;

    balanceOf(arg0: string, overrides?: CallOverrides): Promise<BigNumber>;

    bondingCurve(overrides?: CallOverrides): Promise<string>;

    buy(
      _price: BigNumberish,
      _minTokensReturned: BigNumberish,
      overrides?: CallOverrides
    ): Promise<boolean>;

    created(arg0: string, overrides?: CallOverrides): Promise<boolean>;

    curate(_creator: string, overrides?: CallOverrides): Promise<boolean>;

    initialize(
      _name: string,
      _bondingCurve: string,
      overrides?: CallOverrides
    ): Promise<void>;

    isCuratingLayer(
      arg0: string,
      arg1: string,
      overrides?: CallOverrides
    ): Promise<boolean>;

    layers(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<[string, string] & { creator: string; URI: string }>;

    name(overrides?: CallOverrides): Promise<string>;

    poolBalance(overrides?: CallOverrides): Promise<BigNumber>;

    ppm(overrides?: CallOverrides): Promise<number>;

    removeCuration(
      _creator: string,
      overrides?: CallOverrides
    ): Promise<boolean>;

    removeLayer(overrides?: CallOverrides): Promise<boolean>;

    reserveRatio(overrides?: CallOverrides): Promise<number>;

    sell(
      _tokens: BigNumberish,
      _minETHReturned: BigNumberish,
      overrides?: CallOverrides
    ): Promise<boolean>;

    totalSupply(overrides?: CallOverrides): Promise<BigNumber>;
  };

  filters: {
    Approval(
      owner?: string | null,
      spender?: string | null,
      value?: null
    ): TypedEventFilter<
      [string, string, BigNumber],
      { owner: string; spender: string; value: BigNumber }
    >;

    Buy(
      buyer?: string | null,
      poolBalance?: null,
      totalSupply?: null,
      tokens?: null,
      price?: null
    ): TypedEventFilter<
      [string, BigNumber, BigNumber, BigNumber, BigNumber],
      {
        buyer: string;
        poolBalance: BigNumber;
        totalSupply: BigNumber;
        tokens: BigNumber;
        price: BigNumber;
      }
    >;

    CurationAdded(
      curator?: string | null,
      layerCreator?: string | null
    ): TypedEventFilter<
      [string, string],
      { curator: string; layerCreator: string }
    >;

    CurationRemoved(
      curator?: string | null,
      layerCreator?: string | null
    ): TypedEventFilter<
      [string, string],
      { curator: string; layerCreator: string }
    >;

    LayerAdded(
      creator?: string | null,
      contentURI?: null
    ): TypedEventFilter<
      [string, string],
      { creator: string; contentURI: string }
    >;

    LayerRemoved(
      creator?: string | null
    ): TypedEventFilter<[string], { creator: string }>;

    Sell(
      seller?: string | null,
      poolBalance?: null,
      totalSupply?: null,
      tokens?: null,
      eth?: null
    ): TypedEventFilter<
      [string, BigNumber, BigNumber, BigNumber, BigNumber],
      {
        seller: string;
        poolBalance: BigNumber;
        totalSupply: BigNumber;
        tokens: BigNumber;
        eth: BigNumber;
      }
    >;

    Transfer(
      from?: string | null,
      to?: string | null,
      value?: null
    ): TypedEventFilter<
      [string, string, BigNumber],
      { from: string; to: string; value: BigNumber }
    >;
  };

  estimateGas: {
    addLayer(
      _URI: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    addressToCuratedLayers(
      arg0: string,
      arg1: BigNumberish,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    addressToLayer(arg0: string, overrides?: CallOverrides): Promise<BigNumber>;

    balanceOf(arg0: string, overrides?: CallOverrides): Promise<BigNumber>;

    bondingCurve(overrides?: CallOverrides): Promise<BigNumber>;

    buy(
      _price: BigNumberish,
      _minTokensReturned: BigNumberish,
      overrides?: PayableOverrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    created(arg0: string, overrides?: CallOverrides): Promise<BigNumber>;

    curate(
      _creator: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    initialize(
      _name: string,
      _bondingCurve: string,
      overrides?: PayableOverrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    isCuratingLayer(
      arg0: string,
      arg1: string,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    layers(arg0: BigNumberish, overrides?: CallOverrides): Promise<BigNumber>;

    name(overrides?: CallOverrides): Promise<BigNumber>;

    poolBalance(overrides?: CallOverrides): Promise<BigNumber>;

    ppm(overrides?: CallOverrides): Promise<BigNumber>;

    removeCuration(
      _creator: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    removeLayer(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    reserveRatio(overrides?: CallOverrides): Promise<BigNumber>;

    sell(
      _tokens: BigNumberish,
      _minETHReturned: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<BigNumber>;

    totalSupply(overrides?: CallOverrides): Promise<BigNumber>;
  };

  populateTransaction: {
    addLayer(
      _URI: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    addressToCuratedLayers(
      arg0: string,
      arg1: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    addressToLayer(
      arg0: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    balanceOf(
      arg0: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    bondingCurve(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    buy(
      _price: BigNumberish,
      _minTokensReturned: BigNumberish,
      overrides?: PayableOverrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    created(
      arg0: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    curate(
      _creator: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    initialize(
      _name: string,
      _bondingCurve: string,
      overrides?: PayableOverrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    isCuratingLayer(
      arg0: string,
      arg1: string,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    layers(
      arg0: BigNumberish,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    name(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    poolBalance(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    ppm(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    removeCuration(
      _creator: string,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    removeLayer(
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    reserveRatio(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    sell(
      _tokens: BigNumberish,
      _minETHReturned: BigNumberish,
      overrides?: Overrides & { from?: string | Promise<string> }
    ): Promise<PopulatedTransaction>;

    totalSupply(overrides?: CallOverrides): Promise<PopulatedTransaction>;
  };
}
